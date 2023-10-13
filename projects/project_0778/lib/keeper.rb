# frozen_string_literal: true

require_relative '../models/al_cc_employee_salaries_run'
require_relative '../models/al_cc_employee_salary'
require_relative '../models/al_cc_salary_schedule'

class Keeper
  DEFAULT_MAX_BUFFER_SIZE = 100

  MD5_COLUMNS = {
    'AlCcEmployeeSalary' => %i[
      academic_year college full_name position_title
      hire_date salary_schedule salary_rank
      salary_step employee_status data_source_url
    ],
    'AlCcSalarySchedule' => %i[
      academic_year institution salary_schedule
      job_type salary_rank grade position_title
      salary_period salary_step value data_source_url
    ]
  }

  RUNID_MODELS    = %w[AlCcEmployeeSalary]
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
      'AlCcEmployeeSalary' => [],
      'AlCcSalarySchedule' => []
    }
  end

  def finish
    @run_object.finish unless @run_object.nil?
  end

  def flush(model_class = nil)
    model_clazz = model_class.nil? ? @buffer.keys : [model_class]
    model_clazz.each do |klass|
      klass      = klass.constantize if klass.is_a?(String)
      model_name = klass.name

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

  def mark_deleted
    return if @run_model.nil?

    RUNID_MODELS.each do |model_name|
      model_class  = model_name.constantize
      deleted_recs = model_class.where.not(touched_run_id: @run_id)
      deleted_recs.update_all(deleted: true)
      Hamster.close_connection(model_class)
    end
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

    flush(model_class) if @buffer[model_name].count >= @max_buf_size

    hash
  end

  def touch(model_class)
    model_class = model_class.constantize if model_class.is_a?(String)
    model_name  = model_class.name
    return unless RUNID_MODELS.include?(model_name)

    raise 'Run model not specified.' if @run_model.nil?

    model_class.update_all(touched_run_id: @run_id)
    Hamster.close(model_class)
  end
end
