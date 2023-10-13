# frozen_string_literal: true

class RawNjScCasePdfsOnAws < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])

  self.table_name = 'nj_sc_case_pdfs_on_aws'
  self.inheritance_column = :_type_disabled
end
