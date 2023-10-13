require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end
  
  def run
    (keeper.download_status == 'finish') ? store : download
  end

  def download
    scraper  = Scraper.new
    scraper.do_search
    counter = resume_download
    scraper.skip_pages(counter) unless counter == 1
    while true
      response, next_button = scraper.fetch_page
      save_file(response, "outer_page", "#{@keeper.run_id}/Page_#{counter}")
      page_rows = scraper.fetch_links
      page_rows.each do |row|
        Hamster.logger.info("Processing --> #{row[:link]}")
        file_name  = Digest::MD5.hexdigest row[:link]
        subfolder = (row[:link].include? 'annual') ? 'annual' : 'periodic'
        save_file(row[:html], file_name, "#{@keeper.run_id}/Page_#{counter}/#{subfolder}")
      end
      scraper.navigate if next_button
      break unless next_button
      counter += 1
    end
    scraper.close_browser
    keeper.finish_download
    store
  end

  def store
    folders = peon.list(subfolder: "#{@keeper.run_id}").sort
    folders.each do |folder|
      outer_page = peon.give(subfolder: "#{@keeper.run_id}/#{folder}", file: "outer_page.gz") rescue nil
      data_array = parser.fetch_outer_page_info(outer_page)
      data_array.each do |data|
        link = data[:data_source_url]
        next if link.include? 'paper' or link.nil? or link.empty?
        Hamster.logger.info(link)
        file_name = Digest::MD5.hexdigest link
        subfolder = (link.include? 'annual') ? 'annual' : 'periodic'
        inner_page = peon.give(subfolder: "#{@keeper.run_id}/#{folder}/#{subfolder}", file: file_name + '.gz') rescue nil
        next if inner_page.nil?
        hashes_array = parser.parse_peridoic_page(inner_page, data, "#{@keeper.run_id}") if subfolder == 'periodic'
        hashes_array = parser.parse_annual_page(inner_page, data, "#{@keeper.run_id}") if subfolder == 'annual'
        keeper.insert_record(hashes_array) unless hashes_array.empty?
      end
    end
    keeper.mark_deleted
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser

  def resume_download
    max_folder = peon.list(subfolder: "#{@keeper.run_id}").sort.map{|e| e.split('_').last.to_i}.max rescue nil
    return 1 if max_folder.nil?
    max_folder
  end

  def save_file(response, file_name, store_location)
    peon.put(content:response, file: file_name.to_s, subfolder: store_location)
  end
end
