# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester
  attr_accessor :parser, :keeper, :scraper, :dir_files

  def initialize
    super
    @scraper = Scraper.new
    @parser= Parser.new
    @keeper = Keeper.new
    @dir_files = "#{storehouse}store/"
  end

  def download
    url = "https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/"
    scraper.download(url)
  end

  def store
    store_expenses
    store_committees_data
    store_receipts_data
    #store_contributions_data
  end

  def store_expenses
    list_file_zip = Dir["#{dir_files}*mi_cfr_expenditures*.zip"]
    unzip_file(list_file_zip)
    list_file = Dir["#{dir_files}*mi_cfr_expenditures*.txt"]
    list_file.each do |csv_file|
      parsing_csv = parser.parse_csv_expenses(csv_file)
      keeper.insert_records(parsing_csv, MIRAWExpenses)
      keeper.update_records_expenses(parsing_csv, MIRAWExpenses)
      File.delete(csv_file) if File.exist?(csv_file)
    end
  end

  def store_committees_data
    link = "https://cfrsearch.nictusa.com/committees/spreadsheet?committeeType=%2A&office=%2A&district=%2A&party=%2A&status=active&isExactPhrase=off&useSpreadsheetFormat=on"
    csv_file = scraper.download_files(link)
    parsing_csv = parser.parse_csv_committees(csv_file)
    keeper.insert_records(parsing_csv, MIRAWCommittees)
    keeper.update_records_committees(parsing_csv, MIRAWCommittees)
    File.delete(csv_file) if File.exist?(csv_file)
  end

  def store_receipts_data
    list_file_zip = Dir["#{dir_files}*mi_cfr_receipts*.zip"]
    unzip_file(list_file_zip)
    list_file = Dir["#{dir_files}*_mi_cfr_receipts.txt"]
    list_file.each do |file|
      parsing_csv = parser.parse_csv_receipts(file)
      keeper.insert_records(parsing_csv, MIRAWReceipts)
      keeper.update_records_receipts(parsing_csv, MIRAWReceipts)
      File.delete(file) if File.exist?(file)
    end
  end

  def store_contributions_data
    list_file_zip = Dir["#{dir_files}/*mi_cfr_contributions*.zip"]
    list_file_zip.each do |zip_file|
      parser.unzip_file(zip_file, dir_files)
      parser.split_file(zip_file)

      list_file = Dir["#{dir_files}*split*"]
      list_file.each do |file|
        parsing_csv = parser.parse_csv_contributions(file)
        keeper.insert_records(parsing_csv, MIRAWContributions)
        keeper.update_records_contributions(parsing_csv, MIRAWContributions)
        File.delete(file) if File.exist?(file)
      end
    end
    keeper.finish
  end

  def unzip_file(list_file_zip)
    list_file_zip.each { |zip_file| parser.unzip_file(zip_file, dir_files)}
  end
end
