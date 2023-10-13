class RiCourtRijudiciary < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'ri_court_rijudiciary'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)

  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update ri_court_rijudiciary set touched_run_id=#{touched_run_id} where id=#{id}")
  end

  def self.mark_deleted(id)
    self.connection.execute("update ri_court_rijudiciary set deleted=1 where id=#{id}")
  end
end