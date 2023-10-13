# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = PennsylvaniaParser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    main_response = @scraper.fetch_main_page
    excel_link = @parser.getting_files_link(main_response)
    file_name = excel_link.split('/').last.split('.').first
    excel_file_response = @scraper.getting_response_excel_links(excel_link)
    save_zip(excel_file_response.body,file_name)
    file_handling(excel_link,'a')
  end

  def store
    file_name = file_handling(file_name,'r').first.split('/').last.split('.').first
    path = "#{storehouse}store/Excel_Files/#{file_name}.xls"
    data_array = @parser.getting_data_of_files(path,@keeper.run_id)
    @keeper.insert_records(data_array) unless data_array.empty?
    @keeper.finish
  end

  private

  def save_zip(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/Excel_Files"
    zip_storage_path = "#{storehouse}store/Excel_Files/#{file_name}.xls"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def file_handling(content,flag)
    list = []
    File.open("#{storehouse}store/Excel_Files/Excel_links.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end
end
