# frozen_string_literal: true

require_relative 'mississippi_inmateable'
class MississippiCourtHearing < ActiveRecord::Base
  include MississippiInmateable

  belongs_to :mississippi_charge, foreign_key: :charge_id

  def self.create_and_update!(charge, court_address, hash_data)
    run_id          = charge.touched_run_id
    court_date      = Date.strptime(hash_data[:hearing_data][2], '%m/%d/%Y') rescue nil
    sentence_lenght = hash_data[:hearing_data][0]
    hash_data = {
      charge_id: charge.id,
      court_address_id: court_address.id,
      court_date: court_date,
      sentence_lenght: sentence_lenght.presence
    }
    record = find_by(hash_data)
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
