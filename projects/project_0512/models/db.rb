class Db < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
  self.table_name = 'police_departments'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)

  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update police_departments set touched_run_id=#{touched_run_id} where id=#{id}")
  end

  def self.mark_deleted(id)
    self.connection.execute("update police_departments set deleted=1 where id=#{id}")
  end
end