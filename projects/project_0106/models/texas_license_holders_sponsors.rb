# frozen_string_literal: true

class TexasLicenseHoldersSponsors < ActiveRecord::Base
  self.table_name = 'texas_license_holders_sponsors'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
