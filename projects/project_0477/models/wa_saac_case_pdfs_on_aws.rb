class WaSaacCasePdfsOnAws < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'wa_saac_case_pdfs_on_aws'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)

  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update wa_saac_case_pdfs_on_aws set touched_run_id=#{touched_run_id} where id=#{id}")
  end

end