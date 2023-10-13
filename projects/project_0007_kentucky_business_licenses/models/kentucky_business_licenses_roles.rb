# frozen_string_literal: true
class KentuckyBusinessLicensesRoles < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'kentucky_business_licenses_roles'
end
