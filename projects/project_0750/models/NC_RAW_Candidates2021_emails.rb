# frozen_string_literal: true

class NcRawCandidates2021Emails < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NC_RAW_Candidates2021_emails'
  self.inheritance_column = :_type_disabled
end
