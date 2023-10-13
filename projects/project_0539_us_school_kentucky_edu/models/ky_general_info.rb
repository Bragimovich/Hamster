# frozen_string_literal: true

class KyGeneralInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ky_general_info'

  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update ky_general_info set touched_run_id=#{touched_run_id} where id=#{id}")
  end
  
  def self.update_district_code(id, district_code)
    self.connection.execute("update ky_general_info set number='#{district_code}' where id=#{id}")
  end
end
