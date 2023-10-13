# frozen_string_literal: true

require_relative 'wa_snohomish_inmateable'
class WaSnohomishCharge < ActiveRecord::Base
  include WaSnohomishInmateable

  has_many :wa_snohomish_court_hearings, foreign_key: :charge_id
  def self.create_and_update!(arrest, hash_data)
    run_id = arrest.touched_run_id
    record = arrest.wa_snohomish_charges.find_by(
      number: hash_data[:number],
      docket_number: hash_data[:docket_number],
      disposition: hash_data[:disposition],
      description: hash_data[:description],
    )
    hash_data = hash_data.merge(arrest_id: arrest.id)
    hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
    if record.nil?
      hash_data.merge!(run_id: run_id, touched_run_id: run_id)
      record = create!(hash_data)
    elsif record.md5_hash != hash_data[:md5_hash]
      hash_data.merge!(touched_run_id: run_id)
      record.update!(hash_data)
    else
      record.update!(touched_run_id: run_id)
    end
    record
  end
end
