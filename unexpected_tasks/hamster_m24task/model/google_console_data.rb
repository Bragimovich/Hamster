require_relative 'google_console_data_top_page'
require_relative 'google_console_data_top_query'
require_relative 'google_console_data_run'

class GoogleConsoleData < ActiveRecord::Base

  self.table_name = 'google_console_data'
  has_many :toppage, :class_name => "GoogleConsoleDataTopPage", foreign_key: :site_id
  has_many :topquery, :class_name => "GoogleConsoleDataTopQuery", foreign_key: :site_id
  establish_connection(Storage.use(host: :db02, db: :seo))
  belongs_to :gruns, :class_name => "GoogleConsoleDataRun", foreign_key: "run_id"
end