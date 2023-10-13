# frozen_string_literal: true

require_relative '../models/mi_camp_finance_candidate'
require_relative '../models/mi_camp_finance_committee'
require_relative '../models/mi_camp_finance_contribution'
require_relative '../models/mi_camp_finance_contributor'
require_relative '../models/mi_camp_finance_expenditure'
require_relative '../models/mi_camp_finance_run'

class Keeper
  DEFAULT_MAX_BUFFER_SIZE = 100

  MD5_COLUMNS = {
    'MiCampFinanceCandidate' => %i[
      statement_year committee_id doc_seq_num committee_type committee_name
      full_name last_name first_name middle_name party curr_occupation
      position_sought district full_address address1 address2 city county
      state zip phone email website data_source_url
    ],
    'MiCampFinanceCommittee' => %i[
      candidate_id committee_name committee_number district party election_year
      office_sought county chair_name chair_address chair_city chair_state
      chair_zip chair_phone chair_email treasurer_name treasurer_address
      treasurer_city treasurer_state treasurer_zip treasurer_phone treasurer_email
      parent_entity parent_address parent_city parent_state parent_zip contact_name
      contact_address contact_city contact_state contact_zip contact_phone data_source_url
    ],
    'MiCampFinanceContribution' => %i[
      doc_seq_num page_no contributor_id cont_detail_id doc_stmnt_year doc_type_desc committee_name
      committee_type committee_id type date amount type2 check_number data_source_url
    ],
    'MiCampFinanceContributor' => %i[
      doc_seq_num page_no contributor_id cont_detail_id doc_stmnt_year doc_type_desc
      name address city state zip employer job_title data_source_url
    ],
    'MiCampFinanceExpenditure' => %i[
      doc_seq_num expenditure_type page_num date payee_id detail_id doc_stmnt_year doc_type_desc
      payee_name payee_type amount type type2 check_number committee_name committee_id
      expense_category expense_description expense_purpose extra_expense_description expense_method
      address city county state zip state_loc support_oppose candidate_or_ballot debt_payment vend_name
      vend_addr vend_city vend_state vend_zip gotv_ink_ind data_source_url
    ],
  }

  RUNID_MODELS = %w[
    MiCampFinanceCandidate
    MiCampFinanceCommittee
    MiCampFinanceContribution
    MiCampFinanceContributor
    MiCampFinanceExpenditure
  ]

  UPLOAD_AWS_COLS = []

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
      'MiCampFinanceCandidate'    => [],
      'MiCampFinanceCommittee'    => [],
      'MiCampFinanceContribution' => [],
      'MiCampFinanceContributor'  => [],
      'MiCampFinanceExpenditure'  => []
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

    md5_builder = @md5_builders[model_name]
    if !md5_builder.nil? || RUNID_MODELS.include?(model_name)
      data.each do |hash|
        hash[:md5_hash] = md5_builder.generate(hash) unless md5_builder.nil?
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
end
