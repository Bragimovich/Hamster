# frozen_string_literal: true

require_relative '../models/dc_public_employee_salary'
require_relative '../models/dc_public_employee_salaries_run'

class Keeper
  MAX_BUFFER_SIZE = 500

  def initialize
    @run_object = RunId.new(DcPublicEmployeeSalariesRun)
    @run_id = @run_object.run_id

    @md5_builder =
      MD5Hash.new(
        columns:%i[
          as_of_date
          agency
          appt_type
          first_name
          last_name
          position_title
          grade
          hire_date
          annual_salary
          data_source_url
          page
        ]
      )

    @buffer = []
  end

  def save_data(hash)
    hash[:md5_hash]       = @md5_builder.generate(hash)
    hash[:touched_run_id] = @run_id
    @buffer << hash

    flush if @buffer.count >= MAX_BUFFER_SIZE
  end

  def flush
    return if @buffer.count.zero?

    db_run_ids =
      Hash[
        DcPublicEmployeeSalary.where(
          md5_hash: @buffer.map { |h| h[:md5_hash] }
        )
        .map { |r| [r.md5_hash, r.run_id] }
      ]

    @buffer.each do |hash|
      hash[:run_id] = db_run_ids[hash[:md5_hash]] || @run_id
      hash[:updated_at] = Time.now
    end

    DcPublicEmployeeSalary.upsert_all(@buffer)
    Hamster.close_connection(DcPublicEmployeeSalary)

    @buffer = []
  end

  def mark_deleted
    deleted_recs = DcPublicEmployeeSalary.where.not(touched_run_id: @run_id)
    deleted_recs.update_all(deleted: true)
    Hamster.close_connection(DcPublicEmployeeSalary)
  end

  def finish
    @run_object.finish
  end
end
