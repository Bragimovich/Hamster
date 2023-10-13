class AidByState < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'fafsa_college_student_aid__by_state'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
