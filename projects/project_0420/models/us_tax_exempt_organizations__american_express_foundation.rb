# frozen_string_literal: true

class UsTaxExemptOrganizationsAmericanExpressFoundation < ActiveRecord::Base
  # self.inheritance_column = :some_other
  self.table_name = 'us_tax_exempt_organizations__american_express_foundation'
  establish_connection(Storage.use(host: :db01, db: :usa_raw))
end
