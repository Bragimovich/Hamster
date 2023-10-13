# frozen_string_literal: true

class TexasLicenseHoldersAlternateNames < ActiveRecord::Base
  self.table_name = 'texas_license_holders_alternate_names'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
