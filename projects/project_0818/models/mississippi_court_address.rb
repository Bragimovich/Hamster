# frozen_string_literal: true

require_relative 'mississippi_inmateable'
class MississippiCourtAddress < ActiveRecord::Base
  include MississippiInmateable

  def self.create_and_update!(run_id, hearing_data)
    county = hearing_data[1]
    hash_data = { county: county.presence }
    record = find_by(hash_data)
    if record.nil?
      hash_data.merge!(run_id: run_id, touched_run_id: run_id)
      record = create!(hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join)))
    else
      record.update!(touched_run_id: run_id, deleted: false)
    end
    record
  end
end
