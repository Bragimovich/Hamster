require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @already_fetched = keeper.get_deceased_records
  end

  def download
    scraper = Scraper.new
    ('A'..'Z').each do |letter|
      subfolder_path = "#{keeper.run_id}/Letter_#{letter}"
      downloaded_files = peon.give_list(subfolder: subfolder_path)
      html = scraper.get_outer_page(letter)
      save_file(html.body, "Letter_#{letter}_outer", subfolder_path)
      bar_numbers = parser.get_links(html.body)
      bar_numbers.each do |bar_id|
        file_name = bar_id.to_s
        url = "https://www.coloradosupremecourt.com/Search/Attinfo.asp?Regnum=#{bar_id}"
        next if ((downloaded_files.include? file_name + '.gz') || (@already_fetched.include? file_name))
        html = scraper.get_inner_page(url)
        save_file(html, file_name, subfolder_path)
      end
    end
  end

  def store
    already_fetched_md5 = keeper.already_fetched_md5
    letter_folders = peon.list(subfolder: "#{keeper.run_id}").select{|s| s.include? 'Letter_'}.sort
    letter_folders.each do |letter_folder|
      data_array=[]
      subfolder = "#{keeper.run_id}/#{letter_folder}"
      outer_page = peon.give(subfolder: subfolder, file: "#{letter_folder}_outer.gz")
      outer_data_rows = parser.get_outer_data(outer_page)
      outer_data_rows.each do |row|
        file_name = "#{row[-1].to_s}.gz"
        next if (@already_fetched.include? file_name.gsub(".gz", ""))
        puts "Processing File: #{file_name}"
        body = peon.give(file:file_name, subfolder:subfolder)
        data_hash = parser.get_parsed_content(row, body, keeper.run_id)
        next if already_fetched_md5.include? data_hash["md5_hash"]
        data_array << data_hash
        if data_array.count > 50
          keeper.save_records(data_array)
          data_array = []
        end
      end
      keeper.save_records(data_array) if data_array.count > 0
    end
    keeper.mark_deleted
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser
  
  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end
end