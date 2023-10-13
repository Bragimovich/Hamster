# frozen_string_literal: true

require_relative "../lib/keeper"
require_relative "../lib/parser"
require_relative "../lib/scraper"

class Manager < Hamster::Harvester

  SOURCE_URL = "https://ihsa.org/data/fb/confall.htm"

  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser  = Parser.new
    @keeper  = Keeper.new
    @run_id  = keeper.run_id
    @all_football_conferences = "all_conference"
    @specific_football_conference = "specific_conference"
  end

  def download
    # getting response of conferences list page
    main_response = scraper.main_request(SOURCE_URL)
    # saving conferences list page
    save_file(main_response, "conferences", all_football_conferences)
    logger.info "All Conference Page SAVED !!!"
    # parsing and getting link of all conferences pages to save then
    conferences_link = parser.get_conferences_link(main_response)
    logger.info "Total Conferences Count : #{conferences_link.count}"
    # looping through each conference and saving it
    conferences_link.each do |conference_link|
      logger.info "Processing URL = #{conference_link}"
      file_name = conference_link.split("fb/").last.gsub(".htm", "")
      response = scraper.main_request(conference_link)
      save_file(response, file_name, specific_football_conference)
      logger.info "FILE #{file_name} SAVED !!!"
    end
    logger.info "Donwload DONE !!!"
  end
  
  def store
    store_football_data(all_football_conferences, false)
    store_football_data(specific_football_conference, true)
    keeper.finish
    logger.info "Store DONE !!!"
  end

  private 

  attr_accessor :keeper, :scraper, :parser, :run_id, :all_football_conferences, :specific_football_conference

  def save_file(response, file_name, folder)
    peon.put content: response.body, file: file_name, subfolder: folder
  end
  
  def store_football_data(folder_name, specific_flag)
    saved_files = get_files_from_folder(folder_name)
    saved_files.each do |file|
      logger.info "******** Processing File #{file} *******"
      file_name = file 
      file = peon.give(subfolder: folder_name, file: file)
      parsed_page = parser.parse_html(file)
      data_array = specific_flag ? parser.get_standings_data(parsed_page, file_name) : parser.get_teams_and_conference(parsed_page)
      specific_flag ? keeper.insert_standings_data(data_array) : keeper.insert_teams_and_conference_data(data_array)
    end
    logger.info "******** #{folder_name} Done *******"
  end

  def get_files_from_folder(folder_name)
    saved_files = peon.give_list(subfolder: folder_name)
    logger.info "Found #{saved_files.count} files"
    saved_files
  end

end
