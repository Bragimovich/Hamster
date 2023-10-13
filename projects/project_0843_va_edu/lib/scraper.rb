# frozen_string_literal: true

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}

require 'zip'
require 'csv'
require 'roo'
require 'roo-xls'
require 'spreadsheet'

class Scraper < Hamster::Scraper
  
  # sub_dir: ex: "enrollment"
  # File should be located in ~/HarvestStorehouse/project_0843/store/{sub_dir}/
  def get_csv_file(csv_file, sub_dir)
    file_path = "#{storehouse}store/#{sub_dir}/#{csv_file}"
    CSV.read(file_path)
  end

  def get_json_from_xlsx(file_name, sub_dir)
    file_path = "#{storehouse}store/#{sub_dir}/#{file_name}"
    xsl = Roo::Spreadsheet.open(file_path)
    xsl.as_json
  end

  def get_json_from_full_path_xlsx(file_path)
    xsl = Roo::Spreadsheet.open(file_path, encoding: 'UTF-8')
    xsl.as_json
  end

  def get_enrollment_csv_files
    Dir["#{storehouse}store/enrollment/*#{year-1}#{year}.csv"]
  end

end
