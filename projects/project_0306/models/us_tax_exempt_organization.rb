# frozen_string_literal: true
class UsTaxExemptOrganization < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'us_tax_exempt_organization'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
