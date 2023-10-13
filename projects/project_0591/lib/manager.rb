# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
  end
  
  def download
    page_no = 1
    while true
      url = "https://www.okbar.org/oba-member-search/?pagenum=#{page_no}&filter_9&filter_1&filter_2&filter_3=%25&filter_4&filter_11&mode=all"
      response = scraper.connect_to(url)
      page = parser.parse_page(response.body)
      table_data = parser.get_table_rows(page)
      break if (table_data.text.include? 'no results')
      file_name = Digest::MD5.hexdigest url
      save_page(response, file_name, "#{keeper.run_id}")
      file_handling(url, 'a')
      page_no += 1
    end
  end

  def store
    inserted_md5 = keeper.get_inserted_md5
    links = file_handling(links, 'r')
    links.each do |link|
      file_name = Digest::MD5.hexdigest link
      page_body = peon.give(subfolder: "#{keeper.run_id}", file:file_name)
      data_array,md5_array = parser.parse_data(page_body, link, keeper.run_id, inserted_md5)
      keeper.insert_records(data_array)
      keeper.update_touch_id(md5_array)
    end
    keeper.mark_delete
    FileUtils.rm_rf("#{storehouse}store/#{keeper.run_id}")
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

  def file_handling(content, flag)
    list = []
    File.open("#{storehouse}store/#{keeper.run_id}/links.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write("#{content.to_s}\n")
    end
    list unless list.empty?
  end

end
