# frozen_string_literal: true

require_relative 'nj_doc_inmateable'
class NjDocCharge < ActiveRecord::Base
  include NjDocInmateable

  has_many :nj_doc_court_hearings, foreign_key: :charge_id
  def self.create_and_update!(arrest, hash_data)
    run_id = arrest.touched_run_id
    hash_data = hash_data.merge(arrest_id: arrest.id)
    hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
    record = arrest.nj_doc_charges.find_by(
      counts: hash_data[:counts], 
      description: hash_data[:description]
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
