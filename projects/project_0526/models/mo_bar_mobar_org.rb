class MoBarMobarOrg < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'mo_bar_mobar_org'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)

  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update mo_bar_mobar_org set touched_run_id=#{touched_run_id} where id=#{id}")
  end

  def self.mark_deleted(id)
    self.connection.execute("update mo_bar_mobar_org set deleted=1 where id=#{id}")
  end
end