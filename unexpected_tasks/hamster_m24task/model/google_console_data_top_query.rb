require_relative 'google_console_data'

class GoogleConsoleDataTopQuery < ActiveRecord::Base
  self.table_name = 'google_console_data_top_queries'
  belongs_to :page, class_name: "GoogleConsoleData"
  establish_connection(Storage.use(host: :db02, db: :seo))
end