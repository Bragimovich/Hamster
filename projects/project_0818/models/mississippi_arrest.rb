# frozen_string_literal: true

require_relative 'mississippi_inmateable'
class MississippiArrest < ActiveRecord::Base
  include MississippiInmateable

  has_many :mississippi_charges, foreign_key: :arrest_id
  belongs_to :mississippi_inmate, foreign_key: :inmate_id

  def self.create_and_update!(inmate)
    run_id    = inmate.touched_run_id
    record    = inmate.mississippi_arrest
    hash_data = { inmate_id: inmate.id, data_source_url: inmate.data_source_url }
    hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
    if record.nil?
      hash_data.merge!(run_id: run_id, touched_run_id: run_id)
      record = create!(hash_data)
    elsif record.md5_hash != hash_data[:md5_hash]
      record.update!(hash_data.merge(touched_run_id: run_id))
    else
      record.update!(touched_run_id: run_id, deleted: false)
    end
    record
  end
end
