class WiKenoshaBondsAdditional < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'wi_kenosha_bonds_additional'
  self.inheritance_column = :_type_disabled
end
