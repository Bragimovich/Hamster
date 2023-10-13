# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  URL = 'https://sos.iowa.gov/elections/voterreg/county.html'

  def initialize
    super
    @parser = IowaParser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    main_response = @scraper.connect_to(URL)
    year =  Date.current.year.to_s
    pdf_links = @parser.getting_files_link(main_response,year)
    pdf_links.each do |link|
      file_name = link.split('/').last.split('.').first
      pdf_file_response = @scraper.connect_to(link)
      save_zip(pdf_file_response.body,file_name)
      file_handling(link,'a')
    end
  end

  def store
    pdf_links = file_handling(pdf_links,'r')
    pdf_links.each do |link|
      file_name = link.split('/').last.split('.').first
      path = "#{storehouse}store/Pdf_files/#{file_name}.pdf"
      data_array = @parser.getting_data_of_files(path,@keeper.run_id)
      @keeper.insert_records(data_array) unless data_array.empty?
    end
    @keeper.finish
  end

  private

  def save_zip(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/Pdf_files"
    zip_storage_path = "#{storehouse}store/Pdf_files/#{file_name}.pdf"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def file_handling(content,flag)
    list = []
    File.open("#{storehouse}store/Pdf_files/Pdf_links.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

end
