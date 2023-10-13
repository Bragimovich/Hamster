# frozen_string_literal: true

require_relative 'la_3c_ac_case_concern'
class La3cAcCaseParty < ActiveRecord::Base
  include La3cAcCaseConcern

  self.table_name = 'la_3c_ac_case_party'

  def self.create_and_update!(run_id, hash_data)
    record = find_by(case_id: hash_data[:case_id], party_name: hash_data[:party_name])
    if record.nil?
      hash_data.merge!(run_id: run_id, touched_run_id: run_id)
      create(hash_data)
    elsif record.md5_hash != hash_data[:md5_hash]
      hash_data.merge!(touched_run_id: run_id, deleted: false)
      record.update!(hash_data)
    else
      record.update!(touched_run_id: run_id, deleted: false)
    end
  end
end
