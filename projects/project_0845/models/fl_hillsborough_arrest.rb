# frozen_string_literal: true

require_relative 'fl_hillsborough_inmateable'
class FlHillsboroughArrest < ActiveRecord::Base
  include FlHillsboroughInmateable

  has_many :fl_hillsborough_charges, foreign_key: :arrest_id

  def self.create_and_update!(inmate, hash_data)
    run_id    = inmate.touched_run_id
    record    = inmate.fl_hillsborough_arrest
    hash_data = hash_data.merge(inmate_id: inmate.id)
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
