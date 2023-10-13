# frozen_string_literal: true

require_relative '../models/new_jersey_state_campaign_contributions_csv'
require 'roo'
require 'roo-xls'

class Parser <  Hamster::Scraper

  SOURCE = "https://www.elec.state.nj.us/publicinformation/contrib_quickdownload.htm"
  SUBFOLDER = 'new_jersey_state_campaign_contributions/'
  BASE_URL = "https://www.elec.state.nj.us"

  def initialize
    super
  end

  def store
    peon.list(subfolder: "#{SUBFOLDER}").each do |file|
      year = file.split(".")[-2][-4..-1]
      file_name = file.split(".")[-2][0..-6].split("_").join(" ") 
      path = "#{storehouse}store/#{SUBFOLDER}#{file}" 
      p path

      xlsx = Roo::Spreadsheet.open(path)
      @sheet = xlsx.sheet(0)
      records = @sheet.parse(headers: true)
      records.delete_at(0)
      records.map{|e| e.store("year", "#{year}")}
      records.map{|e| e.store("file_name", "#{file_name}")}
      if records[0].keys.include? "OCCUPATION_NAME"
        records.map{|e|  e["OCCUPATION"] = e.delete "OCCUPATION_NAME"}
      end
      sliced_array = records.each_slice(1000).to_a
      sliced_array.each do |array|
        NewJerseySCCCsv.insert_all(array)
      end
    end
  end
end
