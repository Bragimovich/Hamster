# frozen_string_literal: true

require_relative 'wa_snohomish_inmateable'
class WaSnohomishArrest < ActiveRecord::Base
  include WaSnohomishInmateable

  has_many :wa_snohomish_charges, foreign_key: :arrest_id

  def self.create_and_update!(inmate, hash_data)
    run_id    = inmate.touched_run_id
    record    = inmate.wa_snohomish_arrests.find_by(booking_number: hash_data[:booking_number])
    hash_data = hash_data.merge(inmate_id: inmate.id)
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
