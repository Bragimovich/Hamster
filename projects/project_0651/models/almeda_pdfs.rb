# frozen_string_literal: true
class AlmedaPdfsOnAws < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])

  self.table_name = 'ca_acsc_case_pdfs_on_aws'
  self.inheritance_column = :_type_disabled
end
