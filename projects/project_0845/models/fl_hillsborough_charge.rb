# frozen_string_literal: true

require_relative 'fl_hillsborough_inmateable'
class FlHillsboroughCharge < ActiveRecord::Base
  include FlHillsboroughInmateable

  def self.create_and_update!(arrest, hash_data)
    run_id = arrest.touched_run_id
    hash_data = hash_data.merge(arrest_id: arrest.id)
    hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
    record = arrest.fl_hillsborough_charges.where(
        docket_number: hash_data[:docket_number],
        disposition: hash_data[:disposition],
        description: hash_data[:description]
      ).first
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
