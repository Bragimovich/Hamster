# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester

  URL="https://elect.ky.gov/Resources/Pages/Registration-Statistics.aspx"
  
  def initialize
    super
    @parser = Lawyer_Parser.new
    @scraper = Lawyer_Scraper.new
    @keeper = Keeper.new
  end

  def download
    body = @scraper.get_page(URL)
    parsing = @parser.parsing(body)
    i = 0
    while i<parsing.length
      url = "https://elect.ky.gov#{parsing[i]["link"]}"
      response = @scraper.get_page(url)
      file_name = "#{parsing[i]["link"].split('/').last.split('.').first}-#{parsing[i]["month"]}"
      save_zip(response.body, file_name)
      i+=1
    end
  end

  def store
    excel_files_array = peon.list(subfolder: "#{@keeper.run_id}")
    excel_files_array.each do |file|
      path =  "#{storehouse}store/#{@keeper.run_id}/#{file}"
      final_data = @parser.parsing_xlsx(path, file, @keeper.run_id)
      @keeper.insert_records(final_data) unless final_data.empty?
    end
    @keeper.finish
  end

  private

  def save_zip(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{@keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{@keeper.run_id}/#{file_name}.xls"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

end
