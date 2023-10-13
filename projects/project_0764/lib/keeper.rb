# frozen_string_literal: true

require_relative '../models/ar_employee_salary'
require_relative '../models/ar_employee_salaries_run'

class Keeper
  MAX_BUFFER_SIZE = 200

  def initialize
    @run_object = RunId.new(ArEmployeeSalariesRun)
    @run_id = @run_object.run_id

    @md5_builder =
      MD5Hash.new(
        columns:%i[
          fiscal_year
          agency
          position_title
          employee_name
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

    db_data =
      Hash[
        ArEmployeeSalary
          .where(deleted: false)
          .where(md5_hash: @buffer.map { |h| h[:md5_hash] })
          .map { |r| [r.md5_hash, r] }
      ]

    del_rec_ids = []
    upsert_data = []
    @buffer.each do |hash|
      db_rec  = db_data[hash[:md5_hash]]
      present = db_rec.present? && !del_rec_ids.include?(db_rec.id)

      if present
        next if hash[:data_year].to_i < db_rec.data_year

        to_delete   = db_rec.data_year < hash[:data_year].to_i
        to_delete ||= db_rec.annual_salary != hash[:annual_salary]
        if to_delete
          del_rec_ids << db_rec.id
          db_rec = nil
        end
      end

      if db_rec.blank?
        hash[:run_id] = @run_id
        hash[:id]     = nil
      else
        hash[:run_id] = db_rec.run_id
        hash[:id]     = db_rec.id
      end

      upsert_data << hash
    end

    if del_rec_ids.present?
      ArEmployeeSalary.where(id: del_rec_ids).update_all(deleted: true)
    end
    ArEmployeeSalary.upsert_all(upsert_data)
    Hamster.close_connection(ArEmployeeSalary)

    @buffer = []
  end

  def mark_deleted
    deleted_recs = ArEmployeeSalary.where.not(touched_run_id: @run_id)
    deleted_recs.update_all(deleted: true)
    Hamster.close_connection(ArEmployeeSalary)
  end

  def finish
    @run_object.finish
  end
end
