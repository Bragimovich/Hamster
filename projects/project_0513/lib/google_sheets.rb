# frozen_string_literal: true

require "google/apis/sheets_v4"
require 'google_drive'
require "googleauth"

def worksheets_by_id(id, config)
  session = GoogleDrive::Session.from_config(config)
  spreadsheet = session.spreadsheet_by_key(id)
  spreadsheet.worksheets
end

def spreadsheet_by_id(id, key)
  session = GoogleDrive::Session.from_service_account_key(key)
  session.spreadsheet_by_key(id)
end
