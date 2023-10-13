class Ids < ActiveRecord::Base
  self.table_name = 'il_champaign__arrestee_ids'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
end

