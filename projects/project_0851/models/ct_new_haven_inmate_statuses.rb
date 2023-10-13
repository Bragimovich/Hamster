class CtNewHavenInmateStatuses < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: 'crime_inmate'])	
  self.table_name = 'ct_new_haven_inmate_statuses'
  self.inheritance_column = :_type_disabled
end
