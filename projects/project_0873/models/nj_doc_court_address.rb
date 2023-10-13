# frozen_string_literal: true

require_relative 'nj_doc_inmateable'
class NjDocCourtAddress < ActiveRecord::Base
  include NjDocInmateable

  def self.create_and_update!(run_id, hash_data)
    record = find_by(full_address: hash_data[:full_address])
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
