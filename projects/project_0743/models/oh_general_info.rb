# frozen_string_literal: true

require_relative 'oh_schoolable'
class OhGeneralInfo < ActiveRecord::Base
  include OhSchoolaable
  self.table_name = 'oh_general_info'

  def self.create_and_update!(run_id, hash_data)
    hash_data = HashWithIndifferentAccess.new(hash_data)
    record = find_by(
      is_district: hash_data[:is_district],
      number: hash_data[:number],
      name: hash_data[:name],
      type: hash_data[:type],
      phone: hash_data[:phone]
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

  def full_number
    return number if is_district
    dist_code = OhGeneralInfo.find(district_id) if district_id
    "#{dist_code.number}#{number}"
  end
end

class UsDistricts < ActiveRecord::Base
  include OhSchoolaable

  self.table_name = 'us_districts'
end

class UsSchools < ActiveRecord::Base
  include OhSchoolaable

  self.table_name = 'us_schools'
end
