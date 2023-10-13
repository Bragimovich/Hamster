# frozen_string_literal: true

require_relative 'al_inmateable'
class AlArrest < ActiveRecord::Base
  include AlInmateable

  has_many :al_charges, foreign_key: :arrest_id
  has_many :al_holding_facilities, foreign_key: :arrest_id
  def self.create_and_update!(inmate, hash_data)
    hash_data = hash_data.merge(inmate_id: inmate.id)
    run_id    = inmate.touched_run_id
    record    = inmate.al_arrests.find_by(data_source_url: hash_data[:data_source_url])
    hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
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
