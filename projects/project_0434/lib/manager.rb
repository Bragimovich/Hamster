require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @sub_folder = "#{@keeper.run_id}"
    @scraper = Scraper.new
  end

  def run
    (keeper.download_status == 'finish') ? store : download
  end

  def download(retries = 20)
    begin
      response = scraper.landing_page
      counter = resuming_download
      alreay_downloaded_files = downloaded_files
      counter, response = scraper.skip_pages(counter) unless counter == 1
      while true
        save_file(response, "page_#{counter}", "#{sub_folder}/page_#{counter}")
        page = parser.parse_page(response)
        all_links = parser.get_links(page)
        all_links.each do |link|
          file_name = Digest::MD5.hexdigest link
          next if alreay_downloaded_files.include? file_name
          response = scraper.visit_link(link)
          alreay_downloaded_files << file_name
          save_file(response, file_name, "#{sub_folder}/page_#{counter}")
        end
        counter += 1
        response = scraper.next_page
      end
      scraper.close_browser
      keeper.finish_download
      store
    rescue StandardError => e
      raise if retries <= 1
      download(retries - 1)
    end
  end

  def store
    alreay_downloaded_files = peon.list(subfolder: sub_folder).sort rescue []
    alreay_downloaded_files.each do |file_name|
      inner_files = peon.list(subfolder: "#{sub_folder}/#{file_name}").sort
      next if (inner_files.length == 1) || (inner_files.first.start_with?("page"))
      outer_page = inner_files.select { |file| file.start_with?("page") }.join(" ")
      page_html = peon.give(subfolder: "#{sub_folder}/#{file_name}", file: outer_page)
      page = parser.parse_page(page_html)
      all_links = parser.get_links(page)
      data_array = []
      next if all_links.empty?
      all_links.each do |link|
        inner_file = Digest::MD5.hexdigest link
        next if inner_files.exclude? "#{inner_file}.gz"
        file_html = peon.give(subfolder: "#{sub_folder}/#{file_name}", file: "#{inner_file}.gz")
        data_hash , md5_array = parser.parser(file_html, link, sub_folder)
        next if data_hash.nil? || data_hash.empty?
        data_array << data_hash
        keeper.update_touch_run_id(md5_array)
      end
      keeper.save_records(data_array)
    end
    keeper.mark_deleted if keeper.download_status == 'finish'
    keeper.finish if keeper.download_status == 'finish'
  end

  private

  attr_accessor :keeper, :parser, :scraper,:sub_folder

  def resuming_download
    max_folder = peon.list(subfolder: sub_folder).sort.max.scan(/\d+/).join.to_i rescue nil
    return 1 if max_folder.nil?
    max_folder
  end

  def downloaded_files
    all_folders = peon.list(subfolder: sub_folder) rescue []
    files = []
    all_folders.each do |folder|
      files << peon.list(subfolder: "#{sub_folder}/#{folder}").reject{|e| e.include? 'source_page'}.map{|e| e.gsub(".gz","")}
    end
    files.flatten
  end

  def save_file(html, file_name, sub_folder)
    peon.put content: html, file: file_name, subfolder: sub_folder
  end
end
