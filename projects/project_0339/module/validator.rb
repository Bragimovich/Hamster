# frozen_string_literal: true

require 'csv'

module Validator
  VALID_CSV_FILE_HEADER = ['CorpName', 'DateFormed', 'Citizenship', 'Type', 'Status', 'SOSID', 'RegAgent',
                           'RegAddr1', 'RegAddr2', 'RegCity', 'RegState', 'RegZip', 'RegCounty', 'PitemId',
                           'PrinAddr1', 'PrinAddr2', 'PrinCity', 'PrinState', 'PrinZip', 'PrinCounty'].freeze

  VALID_CSV_FILE_HEADER_FOR_DISSOLVED = ['CorpName', 'DateDissolved', 'Citizenship', 'Type', 'Status', 'Address', 'Address2',
                           'City', 'State', 'Zip', 'County', 'NatureOfBusiness'].freeze

  def valid_csv_file?(csv_file_path)
    # csv = CSV.open(csv_file_path)
    
    csv = CSV.parse(File.open(csv_file_path,
                              &:readline).force_encoding('iso-8859-1').encode('utf-8'), liberal_parsing: true)
    csv.first == VALID_CSV_FILE_HEADER || VALID_CSV_FILE_HEADER_FOR_DISSOLVED
  end
end
