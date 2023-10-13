# frozen_string_literal: true
require_relative 'wi_report_cardable'
class WiGeneralInfo < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'wi_general_info'
  def self.create_and_update!(run_id, hash_data)
    record = find_by(
      is_district: hash_data[:is_district],
      number: hash_data[:number],
      name: hash_data[:name],
      type: hash_data[:type],
      phone: hash_data[:phone]
    )
    if record.nil?
      hash_data.merge!(run_id: run_id, touched_run_id: run_id)
      record = create!(hash_data)
    elsif record.md5_hash != hash_data[:md5_hash]
      hash_data.merge!(touched_run_id: run_id, deleted: false)
      record.update!(hash_data)
    else
      record.update!(touched_run_id: run_id, deleted: false)
    end
    record
  end

  def full_number
    return number if is_district
    dist_code = NcGeneralInfo.find(district_id) if district_id
    "#{dist_code.number}#{number}"
  end
end