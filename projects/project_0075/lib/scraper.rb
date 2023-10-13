# frozen_string_literal: true

require 'yaml'
require_relative '../lib/parser'


class BuildingPermitsScraper < Hamster::Scraper
  SOURCE = 'https://www2.census.gov'
  SUB_PATH = '/econ/bps/County/'
  SUB_FOLDER = 'building_permits_by_county_0075/'
  DAY = 86400
  TEN_MINUTES = 600
  FIVE_MINUTES = 300

  def initialize
    @all_articles = []
    super
  end

  def download
    # Downloads the data from the site and stores in a local file.
    parser = BuildingPermitsParser.new

    mark_as_started
    filter     = ProxyFilter.new(duration: 3.hours, touches: 1000)
    filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    main_page  = get_main_page(filter)
    page_links = get_page_links(main_page, parser)
    @all_dates = []

    begin
      # Saves links to file SUBFOLDER directory.
      save_pages(page_links, filter)

    rescue StandardError => e
      logger.debug e.full_message
      Hamster.report(to: 'seth.putz', message: "Project # 0075 --download: Error - \n#{e}, went to sleep for 5 min", use: :both)
      sleep(FIVE_MINUTES)
    end
    write_to_yaml
    mark_as_finished
  end

  def store(parser)
    # Data stored in local files is inserted into corresponding mySQL tables.
    keeper = BuildingPermitsKeeper.new
    keeper.mark_store_as_started
    process_current_pages(parser)
    keeper.mark_store_as_finished
    files_to_trash
  end

# The cron method downloads any new data into local files, then inserts into the mySQL table(s).

  def cron

  #  Download any new data.
    parser = BuildingPermitsParser.new
    keeper = BuildingPermitsKeeper.new
    new_data = []
    mark_as_started
    filter     = ProxyFilter.new(duration: 3.hours, touches: 1000)
    filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    main_page  = get_main_page(filter)
    page_links = get_page_links(main_page, parser)
    loop do 
      break if page_links.empty?
      popped = page_links.pop
      latest = keeper.check_for_updates(popped)
      latest.nil? || latest.empty? ? new_data << popped : break
    end
    begin
      save_pages(new_data, filter)
      
      rescue StandardError => e
      logger.debug e.full_message
      Hamster.report(to: 'seth.putz', message: "Project # 0075 --download: Error - \n#{e}, went to sleep for 5 min", use: :both)
      sleep(FIVE_MINUTES)
    end
    write_to_yaml
    mark_as_finished

  # Store the downloaded data.
    mark_store_as_started
    process_current_pages(parser)
    mark_store_as_finished
    # The downloaded files, who's data has been inserted into the table, is now moved to the local trash folder in HarvestStorehouse.
    files_to_trash
  end


  private


#        ------------------------------------------
#        ------------------------------------------

  
  def mark_store_as_started
    last_run = BuildingPermitsRuns.last
    BuildingPermitsRuns.find(last_run.id).update(status: 'store started')
  end

  def mark_store_as_finished
    last_run = BuildingPermitsRuns.last
    BuildingPermitsRuns.find(last_run.id).update(status: 'store finished')
  end

  def mark_as_started
    BuildingPermitsRuns.create
    last_run = BuildingPermitsRuns.last
    BuildingPermitsRuns.find(last_run.id).update(status: 'download started')
  end
  
  def mark_as_finished
    last_run = BuildingPermitsRuns.last
    BuildingPermitsRuns.find(last_run.id).update(status: 'download finished')
  end


  def process_current_pages(parser)
    last_run = BuildingPermitsRuns.last
    @run_id = last_run.id
    process_each_file(parser)
  end

  def process_each_file(parser)
    # Each and every downloaded page's data is parsed, cleaned and inserted into the mySQL table.
    begin
      files = peon.give_list(subfolder: SUB_FOLDER)

      loop do
        break if files.empty?
        file = files.pop
        file_content = peon.give(subfolder: SUB_FOLDER, file: file)
        result = parser.parse(file_content, file, @run_id)
        next if result.nil?
        store_row(result)
      end
    rescue => e
      logger.debug e.full_message
      Hamster.report(to: 'seth.putz', message: "Project # 0075 --store: Error - \n#{e}, went to sleep for 5 min", use: :both)
      sleep(FIVE_MINUTES)
    end
  end

  def store_row(data_ary)
    keeper = BuildingPermitsKeeper.new
    keeper.save_to_table(data_ary)
  end

  def add_to_all_links(rows)
    rows.each do |row|
      @all_articles.push(row)
    end
  end
  
  def strip_trailing_spaces(text)
    text.strip.reverse.strip.reverse
  end


  def get_main_page(filter)
    connect_to(SOURCE + SUB_PATH, proxy_filter: filter)&.body
  end

  def get_page_links(main_page, parser)
    
    # Cleaning data for usable link.

    link_end_not_clean = parser.parse_page_links(main_page)
    page_links = []
    link_end   = []

    link_end_not_clean.each do |v|
      link_end << v[0..10]
    end

    # Taking all correct links and adding them to page_links array.
    
    link_end.each {|not_cleaned_link_end| if x.delete("^0-9")[0..1].to_i < 16; next; else; page_links << "https://www2.census.gov/econ/bps/County/#{not_cleaned_link_end}".strip end}

    page_links.each do |article_link|
      article_hash = {
        article_link.split("/").last => [
          article_link,
          article_link.delete("^0-9")
        ]
      }
      add_to_all_links(article_hash)
    end

    # Returns array of correct usable links.

    page_links
  end

  def write_to_yaml
    Dir.mkdir("#{ENV['HOME']}/HarvestStorehouse/project_0075/store/yaml") unless File.exists?(
        "#{ENV['HOME']}/HarvestStorehouse/project_0075/store/yaml"
    )
    yaml_storage_path = "#{ENV['HOME']}/HarvestStorehouse/project_0075/store/yaml/rows.yml"
    
    File.write(yaml_storage_path, @all_articles.to_yaml)
  end

  def save_pages(links, filter)
    links.each do |l|
      new_link = BuildingPermits.find_by(link: l).nil?
      next unless new_link
      begin
        page = connect_to(l , proxy_filter: filter)&.body
        save_file(page, l)
      rescue StandardError => e
        logger.debug e.full_message
      end
    end
  end

  def save_file(html, l)
    name = l.split('/').last
    peon.put content: html, file: "#{name}", subfolder: SUB_FOLDER
  end

  def files_to_trash
    trash_folder = SUB_FOLDER
    peon.list.each do |zip|
      peon.give_list(subfolder: zip).each do |file|
        peon.move(file: file, from: zip, to: trash_folder)
      end
    end
  end
  
  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end

    response
  end
end
