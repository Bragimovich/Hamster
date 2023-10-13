class WaSaacCaseInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'wa_saac_case_info'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
  
  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update wa_saac_case_info set touched_run_id=#{touched_run_id} where id=#{id}")
  end

  def self.mark_deleted(id)
    self.connection.execute("update wa_saac_case_info set deleted=1 where id=#{id}")
  end

  def self.mark_inactive_cases
    sql = "update wa_saac_case_info set status_as_of_date = 'Archived' where id in (select id from (select id from wa_saac_case_info where case_id not in (select distinct(case_id) from wa_saac_case_activities)) as temp)"
    self.connection.execute(sql)
  end

end