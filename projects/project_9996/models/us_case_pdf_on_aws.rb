# frozen_string_literal: true

class USCasePDFAWS < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_courts])
  include Hamster::Granary
  self.inheritance_column = :_type_disabled

  self.table_name = 'us_case_pdfs_on_aws'
end
