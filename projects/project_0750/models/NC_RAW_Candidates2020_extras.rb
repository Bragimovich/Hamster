# frozen_string_literal: true

class NcRawCandidates2020Extras < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NC_RAW_Candidates2020_extras'
  self.inheritance_column = :_type_disabled
end
