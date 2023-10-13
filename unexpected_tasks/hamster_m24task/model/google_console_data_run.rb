require_relative 'google_console_data'

class GoogleConsoleDataRun < ActiveRecord::Base
  self.table_name = 'google_console_data_runs'
  establish_connection(Storage.use(host: :db02, db: :seo))
  has_many :gdata, :class_name => "GoogleConsoleData", foreign_key: "run_id"
end

