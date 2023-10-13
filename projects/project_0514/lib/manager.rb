require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end
  
  def download
    scraper = Scraper.new
    already_downloaded_files = peon.list(subfolder: "#{keeper.run_id}") rescue []
    files_name = scraper.get_main_page
    start_year = keeper.get_max_year
    start_year = start_year += 1
    current_year = Date.today.year
    (start_year..current_year).each do |year|
      file_name = parser.get_file_name(files_name.body, year)
      next if ((file_name.nil?) || (already_downloaded_files.include? file_name.split.join('_')))
      file = scraper.get_zip_file(file_name)
      save_zip(file.body, file_name.split.join('_'))
    end
    keeper.mark_download_status(keeper.run_id)
  end

  def store
    if (keeper.download_status(keeper.run_id)[0].to_s == "true")
      files = peon.list(subfolder: "#{keeper.run_id}").select{|a| a.include? '.zip'}
      files.each do |file|
        file_path = "#{storehouse}store/#{keeper.run_id}/#{file}"
        excel_file_directory = "#{storehouse}store/#{keeper.run_id}/#{file.gsub('.zip','').gsub('-','_')}"
        system("unzip #{file_path} -d #{excel_file_directory}")
        file_name = peon.list(subfolder: "#{keeper.run_id}/#{file.gsub('.zip','').gsub('-','_')}").select{|a| a.include? 'xlsx'}.first
        path = "#{excel_file_directory}/#{file_name}"
        data_array = parser.get_parsed_json(path, file_name.scan(/\d+/).last,keeper.run_id)
        keeper.save_record(data_array) unless data_array.empty?
      end
      keeper.finish
    end
  end

  private

  attr_accessor :keeper, :parser

  def save_zip(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/#{file_name}"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end
end
