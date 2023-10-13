class SchoolSportsTypesVsSchoolInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ihsa_schools__sport_types__schools_info'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)

  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update ihsa_schools__sport_types__schools_info set touched_run_id=#{touched_run_id} where id=#{id}")
  end
end