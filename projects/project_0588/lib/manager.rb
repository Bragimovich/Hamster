require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Scraper
  SUB_FOLDER = "njcourts"

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    page_number = 0
    response = @scraper.get_request("/courts/supreme/appeals?status=All&page=#{page_number}")
    total_page = @parser.total_pages(response)
    puts "total page: #{total_page}".green

    while true
      response = @scraper.get_request("/courts/supreme/appeals?status=All&page=#{page_number}")
      @parser.parse_html_data(response)

      page_number += 1
      puts "page_number #{page_number}"
      break if page_number == total_page.to_i
    end
  end

  def store
    run_id = @keeper.instance_variable_get('@run_id')
    @all_files = peon.give_list(subfolder: SUB_FOLDER)
    @all_files.each do |file_name|
      file_content = peon.give(subfolder: SUB_FOLDER,file: file_name)
      njcourts = JSON.parse(file_content)
      data_hash = @parser.parse_data(njcourts, run_id)
      @keeper.store_data(data_hash)
    end
    @keeper.finish
  end
end
