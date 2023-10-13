# frozen_string_literal: true

require_relative '../models/remax_home_listing'
require_relative '../models/remax_home_property_history'
require_relative '../models/remax_home_listings_run'

class Keeper
  DEFAULT_MAX_BUFFER_SIZE = 100

  MD5_COLUMNS = {
    'RemaxHomeListing'         => %i[
      property_id ouid listing_id state city zip address total_baths full_baths
      bedrooms square_feet acres year_built selling_price status cooling heating
      hoa parking sq_ft_price property_type property_sub_type listed_at_date
      additional_info modify_timestamp data_source_url
    ],
    'RemaxHomePropertyHistory' => %i[property_id property_zip source details date price data_source_url]
  }

  RUNID_MODELS    = %w[RemaxHomeListing RemaxHomePropertyHistory]
  UPLOAD_AWS_COLS = []

  def initialize(options = {})
    @max_buf_size  = options[:max_buffer_size] || DEFAULT_MAX_BUFFER_SIZE
    @max_buf_size  = 50 if @max_buf_size < 50

    @run_model = options[:run_model]
    @run_model = @run_model.constantize if @run_model.is_a?(String)

    unless @run_model.nil?
      @run_object = RunId.new(@run_model)
      @run_id     = @run_object.run_id
    end

    @md5_builders =
      MD5_COLUMNS.each_with_object({}) do |(klass, cols), hash|
        hash[klass] = MD5Hash.new(columns: cols)
      end

    @buffer = {
      'RemaxHomeListing'         => [],
      'RemaxHomePropertyHistory' => []
    }
    @touch_buffer  = []
    @delete_buffer = []
    @zip_last_ts   = nil
  end

  def finish
    @run_object.finish unless @run_object.nil?
  end

  def flush
    flush_data
    flush_touch
    flush_deletion
  end

  def mark_deleted(zip_code)
    return if @run_model.nil?
    return if zip_code.blank?

    @delete_buffer << zip_code
    flush if @delete_buffer.size >= @max_buf_size
  end

  def save_data(model_class, hash)
    model_class = model_class.constantize if model_class.is_a?(String)
    model_name  = model_class.name
    return if @buffer[model_name].nil?

    raise 'Run model not specified.' if RUNID_MODELS.include?(model_name) && @run_model.nil?

    normalize_method = "normalize_#{model_name.underscore}".to_sym
    hash = send(normalize_method, hash) if respond_to?(normalize_method, true)

    unless @md5_builders[model_name].nil?
      hash[:md5_hash] = @md5_builders[model_name].generate(hash)
    end

    hash[:touched_run_id] = @run_id if RUNID_MODELS.include?(model_name)

    add_to_buffer = @md5_builders[model_name].nil?
    add_to_buffer ||= @buffer[model_name].none? { |h| h[:md5_hash] == hash[:md5_hash] }
    @buffer[model_name] << hash if add_to_buffer

    flush_data if @buffer[model_name].size >= @max_buf_size

    hash
  end

  def touch(property_ids = [])
    return if @run_model.nil?
    return if property_ids.blank?

    @touch_buffer += property_ids

    flush_touch if @touch_buffer.size >= @max_buf_size
  end

  def zip_last_modification(zip_code)
    return nil if zip_code.blank?

    if @zip_last_ts.nil?
      @zip_last_ts =
        RemaxHomeListing
        .select('zip, MAX(modify_timestamp) AS ts')
        .group(:zip)
        .each_with_object({}) { |modif, hash| hash[modif[:zip]] = modif[:ts] }

      Hamster.close_connection(RemaxHomeListing)
    end

    return nil if @zip_last_ts.nil?

    @zip_last_ts[zip_code]
  end

  private

  def flush_data
    @buffer.keys.each do |model_name|
      klass = model_name.constantize
      raise 'Run model not specified.' if RUNID_MODELS.include?(model_name) && @run_model.nil?

      next if @buffer[model_name].nil? || @buffer[model_name].count.zero?

      db_query_cols = []
      db_query_cols << :run_id if RUNID_MODELS.include?(model_name)

      aws_cols = UPLOAD_AWS_COLS.select { |ac| ac[0] == model_name }
      aws_cols.each { |ac| db_query_cols << ac[1] << ac[2] }

      unless db_query_cols.size.zero?
        db_values =
          Hash[
            klass.where(
              md5_hash: @buffer[model_name].map { |h| h[:md5_hash] }
            )
            .map { |r| [r.md5_hash, db_query_cols.map { |col| r[col] }] }
          ]

        @buffer[model_name].each do |hash|
          values = db_values[hash[:md5_hash]] || []
          hash[:run_id] = values.shift || @run_id if RUNID_MODELS.include?(model_name)

          aws_cols.each do |ac|
            org_url = values.shift
            aws_url = values.shift
            if !org_url.nil? && !aws_url.nil? && org_url == hash[ac[1]]
              hash[ac[2]] = aws_url
            elsif !hash[ac[1]].nil? && !@upload_aws_cb.nil?
              hash[ac[2]] = @upload_aws_cb.call(model_name, hash, ac[1])
            else
              hash[ac[2]] = nil
            end
          end
        end
      end

      klass.upsert_all(@buffer[model_name])
      Hamster.close_connection(klass)
      @buffer[model_name] = []
    end
  end

  def flush_deletion
    return if @run_model.nil?
    return if @delete_buffer.size.zero?

    recs = RemaxHomeListing.where(zip: @delete_buffer)
    recs.where.not(touched_run_id: @run_id).update_all(deleted: true)
    recs.where(touched_run_id: @run_id).update_all(deleted: false)
    Hamster.close_connection(RemaxHomeListing)

    recs = RemaxHomePropertyHistory.where(property_zip: @delete_buffer)
    recs.where.not(touched_run_id: @run_id).update_all(deleted: true)
    recs.where(touched_run_id: @run_id).update_all(deleted: false)
    Hamster.close_connection(RemaxHomePropertyHistory)

    @delete_buffer = []
  end

  def flush_touch
    return if @run_model.nil?
    return if @touch_buffer.size.zero?

    recs = RemaxHomeListing.where(property_id: @touch_buffer[0][0], modify_timestamp: @touch_buffer[0][1])
    @touch_buffer[1..-1].each do |item|
      recs = recs.or(RemaxHomeListing.where(property_id: item[0], modify_timestamp: item[1]))
    end
    recs.update_all(touched_run_id: @run_id)
    Hamster.close_connection(RemaxHomeListing)

    RemaxHomePropertyHistory
      .where(property_id: @touch_buffer.map { |item| item[0] })
      .update_all(touched_run_id: @run_id)
    Hamster.close_connection(RemaxHomePropertyHistory)

    @touch_buffer = []
  end
end
