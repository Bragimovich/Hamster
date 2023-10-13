# frozen_string_literal: true

require_relative 'al_inmateable'
class AlHoldingFacility < ActiveRecord::Base
  include AlInmateable

  def self.create_and_update!(arrest, hash_data)
    run_id = arrest.touched_run_id
    hash_data = hash_data.merge(arrest_id: arrest.id)
    hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
    record = arrest.al_holding_facilities.find_by(
      start_date: hash_data[:start_date],
      planned_release_date: hash_data[:planned_release_date],
      total_time: hash_data[:total_time],
      data_source_url: hash_data[:data_source_url]
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
end
