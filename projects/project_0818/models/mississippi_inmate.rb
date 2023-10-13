# frozen_string_literal: true

require_relative 'mississippi_inmateable'
class MississippiInmate < ActiveRecord::Base
  include MississippiInmateable

  has_one :mississippi_inmate_id, foreign_key: :inmate_id
  has_one :mississippi_inmate_additional_info, foreign_key: :inmate_id
  has_one :mississippi_physical_location_history, foreign_key: :inmate_id
  has_one :mississippi_mugshot, foreign_key: :inmate_id
  has_one :mississippi_arrest, foreign_key: :inmate_id

  def self.create_and_update!(run_id, hash_data)
    record = find_by(full_name: hash_data[:full_name], data_source_url: hash_data[:data_source_url])
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
