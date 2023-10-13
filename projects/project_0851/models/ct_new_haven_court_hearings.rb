class CtNewHavenCourtHearings < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: 'crime_inmate'])	
  self.table_name = 'ct_new_haven_court_hearings'
  self.inheritance_column = :_type_disabled
end
