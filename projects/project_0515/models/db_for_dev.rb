class DbForDev < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'counts_of_death_by_cause_week_state__description'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)

  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update counts_of_death_by_cause_week_state__description set touched_run_id=#{touched_run_id} where id=#{id}")
  end

  def self.mark_deleted(id)
    self.connection.execute("update counts_of_death_by_cause_week_state__description set deleted=1 where id=#{id}")
  end
end