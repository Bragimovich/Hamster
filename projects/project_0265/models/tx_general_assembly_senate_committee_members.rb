class AssemblySenateCommetieMembers < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name         = 'tx_general_assembly_senate_committee_members'
  self.inheritance_column = :_type_disabled
end
