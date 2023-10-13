# frozen_string_literal: true
class UsTaxExemptOrganizationRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'us_tax_exempt_organization_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
