# frozen_string_literal: true

class GasBuddyZip < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'gasbuddy_v2_zips'
end
