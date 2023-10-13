# frozen_string_literal: true

class KyAdministrators < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ky_administrators'
  self.logger = Logger.new(STDOUT)
  
  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update ky_administrators set touched_run_id=#{touched_run_id} where id=#{id}")
  end
end
