# frozen_string_literal: true

require_relative 'nj_doc_inmateable'
class NjDocCourtHearing < ActiveRecord::Base
  include NjDocInmateable

  def self.create_and_update!(charge, hash_data)
    run_id = charge.touched_run_id
    hash_data = hash_data.merge(charge_id: charge.id)
    hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
    record = charge.al_court_hearings.find_by(case_number: hash_data[:case_number], data_source_url: hash_data[:data_source_url])
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
