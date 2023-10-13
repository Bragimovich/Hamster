# frozen_string_literal: true

require_relative '../models/ct_hartfold_arrest'
require_relative '../models/ct_hartfold_bond'
require_relative '../models/ct_hartfold_holding_facilities_address'
require_relative '../models/ct_hartfold_holding_facility'
require_relative '../models/ct_hartfold_inmate_id'
require_relative '../models/ct_hartfold_inmate_run'
require_relative '../models/ct_hartfold_inmate'
require_relative '../models/ct_hartfold_mugshot'
require_relative '../models/ct_hartfold_parole_booking_date'

class Keeper
  DEFAULT_MAX_BUFFER_SIZE = 100

  MD5_COLUMNS = {
    'CtHartfoldArrest'                   => %i[inmate_id status booking_date booking_agency],
    'CtHartfoldBond'                     => %i[arrest_id bond_amount],
    'CtHartfoldHoldingFacilitiesAddress' => %i[full_address street_address city state zip],
    'CtHartfoldHoldingFacility'          => %i[arrest_id holding_facilities_addresse_id facility planned_release_date max_release_date],
    'CtHartfoldInmateId'                 => %i[inmate_id number],
    'CtHartfoldInmate'                   => %i[full_name first_name middle_name last_name birthdate],
    'CtHartfoldMugshot'                  => %i[immate_id original_link],
    'CtHartfoldParoleBookingDate'        => %i[immate_id date]
  }

  RUNID_MODELS = %w[
    CtHartfoldArrest
    CtHartfoldBond
    CtHartfoldHoldingFacilitiesAddress
    CtHartfoldHoldingFacility
    CtHartfoldInmateId
    CtHartfoldInmate
    CtHartfoldMugshot
    CtHartfoldParoleBookingDate
  ]

  UPLOAD_AWS_COLS = [['CtHartfoldMugshot', :original_link, :aws_link, :original_link_dl]]

  def initialize(options = {})
    @max_buf_size  = options[:max_buffer_size] || DEFAULT_MAX_BUFFER_SIZE
    @max_buf_size  = 50 if @max_buf_size < 50
    @upload_aws_cb = options[:upload_aws_cb]

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
      'CtHartfoldArrest'                   => [],
      'CtHartfoldBond'                     => [],
      'CtHartfoldHoldingFacilitiesAddress' => [],
      'CtHartfoldHoldingFacility'          => [],
      'CtHartfoldInmateId'                 => [],
      'CtHartfoldInmate'                   => [],
      'CtHartfoldMugshot'                  => [],
      'CtHartfoldParoleBookingDate'        => []
    }
  end

  def finish
    @run_object.finish unless @run_object.nil?
  end

  def flush(model_class = nil)
    model_clazz = model_class.nil? ? @buffer.keys : [model_class]
    model_clazz.each do |klass|

      klass = klass.constantize if klass.is_a?(String)
      flush_internal(klass)
    end
  end

  def mark_deleted(model_class = nil, filter_col = nil, filter_vals = nil)
    return if @run_model.nil?

    model_names =
      if model_class.nil?
        RUNID_MODELS
      else
        model_class = model_class.constantize if model_class.is_a?(String)
        model_name  = model_class.name
        RUNID_MODELS.include?(model_name) ? [model_name] : []
      end

    model_names.each do |model_name|
      no_filter   = filter_col.nil? || filter_vals.nil? || !filter_vals.is_a?(Array) || filter_vals.size.zero?
      model_class = model_name.constantize
      filter_recs = no_filter ? model_class : model_class.where(filter_col.to_sym => filter_vals)

      filter_recs.where.not(touched_run_id: @run_id).update_all(deleted: true)
      filter_recs.where(touched_run_id: @run_id).update_all(deleted: false)
      Hamster.close_connection(model_class)
    end
  end

  def save_data(model_class, hash)
    model_class = model_class.constantize if model_class.is_a?(String)
    model_name  = model_class.name
    return if @buffer[model_name].nil?

    raise 'Run model not specified.' if RUNID_MODELS.include?(model_name) && @run_model.nil?

    @buffer[model_name] << hash
    flush(model_class) if @buffer[model_name].count >= @max_buf_size
  end

  def touch(model_class, filter_col = nil, filter_vals = nil)
    raise 'Run model not specified.' if @run_model.nil?

    return if model_class.nil?

    model_class = model_class.constantize if model_class.is_a?(String)
    model_name  = model_class.name
    return unless RUNID_MODELS.include?(model_name)

    no_filter =
      filter_col.nil? || filter_vals.nil? || !filter_vals.is_a?(Array) || filter_vals.size.zero?

    recs = model_class.all
    recs = recs.where(filter_col.to_sym => filter_vals) unless no_filter

    recs.update_all(touched_run_id: @run_id)
    Hamster.close_connection(model_class)
  end

  private

  def fetch_model_ids_by_hash(data, model, hash_key)
    ids = Hash[
      model.where(
        md5_hash: data.map { |h| h[hash_key] }
      )
      .map { |r| [r.md5_hash, r.id] }
    ]
    Hamster.close_connection(model)
    ids
  end

  def flush_internal(model_class)
    model_name = model_class.name
    raise 'Run model not specified.' if RUNID_MODELS.include?(model_name) && @run_model.nil?
    return if @buffer[model_name].nil? || @buffer[model_name].count.zero?

    normalize_method = "normalize_#{model_name.underscore}".to_sym
    data =
      if respond_to?(normalize_method, true)
        send(normalize_method, @buffer[model_name])
      else
        @buffer[model_name]
      end

    unless @md5_builders[model_name].nil?
      data.each do |hash|
        hash[:md5_hash] = @md5_builders[model_name].generate(hash)
        hash[:touched_run_id] = @run_id if RUNID_MODELS.include?(model_name)
      end
    end

    db_query_cols = %i[id]
    db_query_cols << :run_id if RUNID_MODELS.include?(model_name)

    aws_cols = UPLOAD_AWS_COLS.select { |ac| ac[0] == model_name }
    aws_cols.each { |ac| db_query_cols << ac[1] << ac[2] }

    db_values =
      Hash[
        model_class.where(
          md5_hash: data.map { |h| h[:md5_hash] }
        )
        .map { |r| [r.md5_hash, db_query_cols.map { |col| r[col] }] }
      ]

    data.each do |hash|
      values = db_values[hash[:md5_hash]] || []
      hash[:id] = values.shift
      hash[:run_id] = values.shift || @run_id if RUNID_MODELS.include?(model_name)

      aws_cols.each do |ac|
        org_url = values.shift
        aws_url = values.shift
        if !org_url.nil? && !aws_url.nil? && org_url == hash[ac[1]]
          hash[ac[2]] = aws_url
        elsif !hash[ac[1]].nil? && !@upload_aws_cb.nil?
          hash[ac[2]] = @upload_aws_cb.call(model_name, hash, ac[3].presence || ac[1])
        else
          hash[ac[2]] = nil
        end
        hash.delete(ac[3]) if ac[3].present?
      end
    end

    model_class.upsert_all(data)
    Hamster.close_connection(model_class)
    @buffer[model_name] = []
  end

  def normalize_ct_hartfold_arrest(data)
    flush_internal(CtHartfoldInmateId)

    data.each do |hash|
      hash[:inmate_md5] = Digest::MD5.hexdigest(hash[:inmate_plain])
    end
    inmate_ids = fetch_model_ids_by_hash(data, CtHartfoldInmate, :inmate_md5)

    data.map do |hash|
      {
        booking_agency:  hash[:booking_agency],
        booking_date:    hash[:booking_date],
        data_source_url: hash[:data_source_url],
        inmate_id:       inmate_ids[hash[:inmate_md5]],
        status:          hash[:status]
      }
    end
  end

  def normalize_ct_hartfold_bond(data)
    flush_internal(CtHartfoldArrest)

    data.each do |hash|
      hash[:inmate_md5] = Digest::MD5.hexdigest(hash[:inmate_plain])
    end
    inmate_ids = fetch_model_ids_by_hash(data, CtHartfoldInmate, :inmate_md5)

    data.each do |hash|
      hash[:arrest_md5] = Digest::MD5.hexdigest("#{inmate_ids[hash[:inmate_md5]]}#{hash[:arrest_plain]}")
    end
    arrest_ids = fetch_model_ids_by_hash(data, CtHartfoldArrest, :arrest_md5)

    data.map do |hash|
      {
        arrest_id:       arrest_ids[hash[:arrest_md5]],
        bond_amount:     hash[:bond_amount],
        data_source_url: hash[:data_source_url]
      }
    end
  end

  def normalize_ct_hartfold_holding_facility(data)
    flush_internal(CtHartfoldArrest)
    flush_internal(CtHartfoldHoldingFacilitiesAddress)

    data.each do |hash|
      hash[:inmate_md5] = Digest::MD5.hexdigest(hash[:inmate_plain])
    end
    inmate_ids = fetch_model_ids_by_hash(data, CtHartfoldInmate, :inmate_md5)

    data.each do |hash|
      hash[:arrest_md5] = Digest::MD5.hexdigest("#{inmate_ids[hash[:inmate_md5]]}#{hash[:arrest_plain]}")
    end
    arrest_ids = fetch_model_ids_by_hash(data, CtHartfoldArrest, :arrest_md5)

    data.each do |hash|
      hash[:address_md5] = Digest::MD5.hexdigest(hash[:address_plain])
    end
    address_ids = fetch_model_ids_by_hash(data, CtHartfoldHoldingFacilitiesAddress, :address_md5)

    data.map do |hash|
      {
        arrest_id:                      arrest_ids[hash[:arrest_md5]],
        data_source_url:                hash[:data_source_url],
        facility:                       hash[:facility],
        holding_facilities_addresse_id: address_ids[hash[:address_md5]],
        max_release_date:               hash[:max_release_date],
        planned_release_date:           hash[:planned_release_date]
      }
    end
  end

  def normalize_ct_hartfold_inmate_id(data)
    flush_internal(CtHartfoldInmate)

    data.each do |hash|
      hash[:inmate_md5] = Digest::MD5.hexdigest(hash[:inmate_plain])
    end
    inmate_ids = fetch_model_ids_by_hash(data, CtHartfoldInmate, :inmate_md5)

    data.map do |hash|
      {
        data_source_url: hash[:data_source_url],
        inmate_id:       inmate_ids[hash[:inmate_md5]],
        number:          hash[:inmate_number]
      }
    end
  end

  def normalize_ct_hartfold_mugshot(data)
    flush_internal(CtHartfoldInmate)

    data.each do |hash|
      hash[:inmate_md5] = Digest::MD5.hexdigest(hash[:inmate_plain])
    end
    inmate_ids = fetch_model_ids_by_hash(data, CtHartfoldInmate, :inmate_md5)

    data.map do |hash|
      {
        data_source_url:  hash[:data_source_url],
        immate_id:        inmate_ids[hash[:inmate_md5]],
        original_link:    hash[:original_link],
        original_link_dl: hash[:original_link_dl]
      }
    end
  end

  def normalize_ct_hartfold_parole_booking_date(data)
    flush_internal(CtHartfoldInmate)

    data.each do |hash|
      hash[:inmate_md5] = Digest::MD5.hexdigest(hash[:inmate_plain])
    end
    inmate_ids = fetch_model_ids_by_hash(data, CtHartfoldInmate, :inmate_md5)

    data.map do |hash|
      {
        date:      hash[:date],
        immate_id: inmate_ids[hash[:inmate_md5]]
      }
    end
  end
end
