# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'district_columbia__dcd_uscourts_gov__runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  # establish_connection(Storage[host: :localhost, db: :press_releases])
  # self.logger = Logger.new(STDOUT)
  # self.inheritance_column = :_type_disabled
end
