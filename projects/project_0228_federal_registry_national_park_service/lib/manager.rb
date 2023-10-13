# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize
    super
    @start_date = Date.today.days_ago(10).to_s
    @current_date = Date.today.to_s
    @parser = NpsParser.new
    @keeper = Keeper.new
    @Domain = "https://www.nps.gov"
    @already_processed = @keeper.fetch_links
    @subfolder = "#{@keeper.run_id}"
  end

  def download
    scraper = Scraper.new
    main_page = scraper.get_main_page(@start_date,@current_date)
    save_file(main_page,"main_page", @subfolder)
    records = @parser.get_cleaned_json(main_page.body)
    records.each do |record|
      link = @Domain + record["PageURL"]
      next if (check_links(link))
      document = scraper.connect_to(URI.escape(link))
      file_name = Digest::MD5.hexdigest link
      save_file(document,file_name, @subfolder)
    end
  end

  def store
    main_page = peon.give(subfolder: @subfolder, file: "main_page") rescue nil
    return if main_page.nil?
    records = @parser.get_cleaned_json(main_page)
    data_array = []
    records.each do |record|
      tags = []
      link = @Domain + record["PageURL"]
      next if (check_links(link))
      file_name = Digest::MD5.hexdigest link
      current_file = peon.give(subfolder: @subfolder, file: file_name)
      data,tags = @parser.inner_page_parser(current_file,link,record,@keeper.run_id)
      data_array << data unless (data.nil? || data.empty?)
      @keeper.tags_table_insertion(tags,link) unless (tags.nil? || tags.empty?)
    end
    @keeper.insert(data_array) unless data_array.empty?
    @keeper.finish
  end

  def save_file(html, file_name, sub_folder)
    peon.put content: html.body, file: file_name, subfolder: sub_folder
  end

  def check_links(link)
    ((link.include? "govAlertChooser") ||  (link.include? "govLocationCategory") || (link.include? "media") || (@already_processed.include? link))?  true : false
  end
end
