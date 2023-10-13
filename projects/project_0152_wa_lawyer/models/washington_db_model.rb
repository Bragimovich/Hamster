# frozen_string_literal: true
class WashingtonLawyerStatus < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'washington'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)

  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update washington set touched_run_id=#{touched_run_id} where id=#{id}")
  end

  def self.mark_deleted(id)
    self.connection.execute("update washington set deleted=1 where id=#{id}")
  end

end

class WashingtonLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'washington_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end