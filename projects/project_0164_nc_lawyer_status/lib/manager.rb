# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = NorthCarolinaParser.new
    @keeper = Keeper.new
    @already_inserted_links = @keeper.already_inserted_links
    @scraper = Scraper.new
  end

  def download
    get_downloaded_files
    main_page   = scraper.fetch_main_page
    body_info   = parser.get_profession(main_page)
    start_index = peon.list(subfolder: "#{keeper.run_id}").max rescue []
    start_index = 'aaa' if start_index.empty?
    (start_index..'zzz').each do |search_text|
      @flag = false
      search_main_page = scraper.search_main_page(body_info, search_text)
      cookie_value = search_main_page.headers['set-cookie']
      profession_page_html = scraper.profession_page_html(cookie_value)
      search_text = search_text.downcase.gsub(" ","_").gsub("/","_")
      lawyers_links = parser.get_lawyer_links(profession_page_html)
      next if lawyers_links.empty?
      download_inner_pages(lawyers_links, cookie_value, search_text)
      save_page(profession_page_html, "#{search_text}_outer_page", "#{keeper.run_id}/#{search_text}") if @flag
    end
  end

  def store
    inserted_records = keeper.already_inserted_md5
    all_folders = peon.list(subfolder: "#{keeper.run_id}").sort rescue []
    all_folders.each do |inner_folder|
      lawyers_info_array = []
      outer_page_content = peon.give(subfolder: "#{keeper.run_id}/#{inner_folder}", file: "#{inner_folder}_outer_page.gz")
      lawyers_links = parser.get_inner_links(outer_page_content)
      lawyers_links.each do |link|
        next if @already_inserted_links.include? link

        file_name  = Digest::MD5.hexdigest link
        inner_page = peon.give(subfolder: "#{keeper.run_id}/#{inner_folder}", file: "#{file_name}.gz") rescue nil
        next if inner_page.nil? or inner_page.include? '<title>Object moved</title>'

        data_hash = parser.lawyers_info_parser(inner_page, link, keeper.run_id)
        next if inserted_records.include? data_hash[:md5_hash]

        lawyers_info_array << data_hash
      end
      keeper.insert_records(lawyers_info_array) unless lawyers_info_array.empty?
    end
    keeper.mark_deleted
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def download_inner_pages(lawyers_links, cookie_value, search_text)
    lawyers_links.each do |inner_link|
      next if @already_inserted_links.include? inner_link

      file_name = Digest::MD5.hexdigest inner_link
      next if @all_files.include? file_name + '.gz'
      @all_files << "#{file_name}.gz"
      @flag = true
      lawyers_info_html = scraper.scrape_inner_page(inner_link, cookie_value)
      save_page(lawyers_info_html, file_name, "#{keeper.run_id}/#{search_text}")
    end
  end

  def get_downloaded_files
    @all_files = []
    all_folders = peon.list(subfolder: "#{keeper.run_id}").sort rescue []
    all_folders.each do |inner_folder|
      files = peon.give_list(subfolder: "#{keeper.run_id}/#{inner_folder}")
      @all_files = @all_files + files
    end
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

end
