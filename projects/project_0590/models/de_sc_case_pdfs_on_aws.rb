# frozen_string_literal: true

class DeScCasePdfsAws < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :us_court_cases])
    self.table_name = 'de_sc_case_pdfs_on_aws'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new($stdout)
  end
