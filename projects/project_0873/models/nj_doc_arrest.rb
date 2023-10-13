# frozen_string_literal: true

require_relative 'nj_doc_inmateable'
class NjDocArrest < ActiveRecord::Base
  include NjDocInmateable

  has_many :nj_doc_charges, foreign_key: :arrest_id
  has_many :nj_doc_holding_facilities, foreign_key: :arrest_id
  def self.create_and_update!(inmate, hash_data)
    hash_data = hash_data.merge(inmate_id: inmate.id)
    run_id    = inmate.touched_run_id
    record    = inmate.nj_doc_arrests.find_by(booking_date: hash_data[:booking_date], data_source_url: hash_data[:data_source_url])
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
