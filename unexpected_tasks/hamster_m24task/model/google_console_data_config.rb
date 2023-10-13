require 'googleauth'
require 'googleauth/service_account'
require "google/apis/sheets_v4"
require 'stringio'

SCOPE = ["https://www.googleapis.com/auth/webmasters.readonly",
         Google::Apis::SheetsV4::AUTH_SPREADSHEETS]

class GoogleConsoleDataConfig < ActiveRecord::Base
  attr_reader :authorizer
  self.table_name = 'google_console_data_config_prod'
  establish_connection(Storage.use(host: :db02, db: :seo))

  def get_token
    io = StringIO.new(json_key)
    @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: io,
      scope: SCOPE)
    @authorizer.fetch_access_token!
  end

end
