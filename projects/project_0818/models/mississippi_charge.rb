# frozen_string_literal: true

require_relative 'mississippi_inmateable'
class MississippiCharge < ActiveRecord::Base
  include MississippiInmateable

  belongs_to :mississippi_arrest, foreign_key: :arrest_id
  has_one :mississippi_court_hearing, foreign_key: :charge_id

  def self.create_and_update!(arrest, hash_data)
    run_id = arrest.touched_run_id
    hash_data = hash_data.merge(arrest_id: arrest.id)
    record = arrest.mississippi_charges.find_by(hash_data)
    if record.nil?
      hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
      hash_data.merge!(run_id: run_id, touched_run_id: run_id, arrest_id: arrest.id)
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
