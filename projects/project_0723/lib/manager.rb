# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester

  SCHOOL_DATA_URL = 'https://www.ihsa.org/data/school/'
  BASEBALL_HISTORY_URL = "https://ihsa.org/data/ba/records/index.htm?NOCACHE=6:16:29%20AM"
  

  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @schools_folder = 'schools_folder'
    @box_scores_folder = 'box_scores_play_by_play'
    @school_matching = 'school_matching'
    @school_matching_htmls = 'school_matching_htmls'
    @run_id = keeper.run_id
  end

  def download
    download_school_data
    download_baseball_data
    logger.info '***'*20, "Scrape - Download Done!", '***'*20
  end

  def games_update
    keeper.fix_games_data
  end
  
  def alias
    download_school_links_page
    store_school_alias_links
    store_school_matching
    store_other_all_alias
  end
  
  def store
    store_school_data
    store_baseball_data
    logger.info '***'*20, "Scrape - Store Done!", '***'*20
  end
  
  def relation
    keeper.update_relations
    logger.info '***'*20, "Scrape - Relation Updated Done!", '***'*20
  end

  private 

  attr_accessor :keeper, :scraper, :parser, :schools_folder, :run_id, :box_scores_folder, :school_matching, :school_matching_htmls

  def save_file(response, file_name, folder)
    peon.put content: response.body, file: file_name, subfolder: folder
  end

  def download_school_links_page
    ('a'..'z').each do |letter|
      url = "#{SCHOOL_DATA_URL}#{letter}.htm"
      response = scraper.fetch_page(url)
      file_name = url.split("/").last.split(".").first.to_s
      save_file(response, file_name, school_matching_htmls)
      logger.info '***'*10, "Scrape - Page Saved!", '***'*10
     
    end
  end

  def download_school_data
    inserted_schools_db = already_procssed_schools
    stored_schools = already_stored_schools
    ('a'..'z').each do |letter|
      url = "#{SCHOOL_DATA_URL}#{letter}.htm"
      response = scraper.fetch_page(url)
      body = parser.parse_html(response.body)
      school_links = parser.get_school_links(body)
      p "Found #{school_links.count} links for letter #{letter}"
      school_links.each do |link|
        url = SCHOOL_DATA_URL + link
        next if inserted_schools_db.include? url
        response = scraper.fetch_page(url)
        file_name = link.split("/").last.split(".").first.to_s
        next if stored_schools.include? "#{file_name}.gz"
        save_file(response, file_name, schools_folder)
        logger.info '***'*10, "Scrape - Page Saved!", '***'*10
      end 
    end
  end

  def already_procssed_schools
    keeper.already_procssed_schools 
  end
  
  def already_stored_schools
    saved_files = peon.give_list(subfolder: schools_folder)
  end

  def download_baseball_data
    response = scraper.fetch_page(BASEBALL_HISTORY_URL)
    body = parser.parse_html(response.body)
    box_scores_links = parser.get_box_scores_link(body)
    box_scores_links.each do |link|
      next unless link['file_name'].include?('2010-11')
      break if link['file_name'].include?('2009-10')
      response = scraper.fetch_page(link['link_url'])
      file_name = link['file_name']
      save_file(response, file_name, box_scores_folder)
      logger.info '***'*10, "Scrape - Page Saved!", '***'*10
    end
  end

  def store_school_matching
    saved_files = Dir["#{storehouse}store/school_matching/*.csv"]
    logger.info "Found #{saved_files.count} files"
    saved_files.each do |file|
      logger.info "Processing file #{file}"
      alias_csv_array = parser.get_csv_schools(file, run_id)
      alias_csv_array.each do |alias_row|
        # Iterate over the aliases in each row
        alias_row.each do |alias_key, alias_value|
          # Skip the "aliase_name" key as we will use it as the column name
          next if alias_key == "aliase_name" or alias_value.nil?
          alias_hash = {}
          school_id, data_source_url = keeper.get_school_id_by_aliase_name(alias_row["aliase_name"])
          alias_hash["school_id"] = school_id
          alias_hash["aliase_name"] = alias_value  # Set the alias value as the column value
          alias_hash["data_source_url"] = data_source_url
          alias_hash["run_id"] = run_id
          keeper.insert_alias_data(alias_hash)
        end
      end
    end
    keeper.finish
  end

  def store_school_alias_links
    saved_files = peon.give_list(subfolder: school_matching_htmls)
    logger.info "Found #{saved_files.count} files"
    saved_files.each do |file|
      logger.info "Processing file #{file}"
      link = "#{SCHOOL_DATA_URL}#{file.split(".").first.to_s}.htm"
      file = peon.give(subfolder: school_matching_htmls, file: file)
      parsed_page = parser.parse_html(file)
      data_hash_array = parser.get_link_alias(parsed_page, link)
      data_hash_array.each do |data_row|
        data_hash = {}
        school_name = data_row["alias"]
        school_url  = "#{SCHOOL_DATA_URL}#{data_row["school_page_url"]}"
        data_hash["school_id"]       = keeper.get_school_id_by_url(school_url)
        next if data_hash["school_id"].nil?
        data_hash["aliase_name"]     = data_row["alias"]
        data_hash["data_source_url"] = data_row["data_source_url"]
        data_hash["run_id"]          = run_id
        keeper.insert_alias_data(data_hash)
      end
    end
    keeper.finish
  end

  def store_other_all_alias
    schools =  keeper.get_all_schools
    schools.each do |school|
      data_hash = {}
      data_hash["school_id"]       = school.id
      data_hash["aliase_name"]     = school.aliase_name
      data_hash["data_source_url"] = school.data_source_url
      data_hash["run_id"]          = run_id
      keeper.insert_alias_data(data_hash)
    end
    keeper.finish
  end

  def store_school_data
    inserted_schools_db = already_procssed_schools
    saved_files = peon.give_list(subfolder: schools_folder)
    logger.info "Found #{saved_files.count} files"
    saved_files.each do |file|
      logger.info "Processing file #{file}"
      link = "#{SCHOOL_DATA_URL}schools/#{file.split(".").first.to_s}.htm"
      next if inserted_schools_db.include? link
      next if file.include?('1504') or  file.include?('2958') or file.include?('2737') or file.include?('2848')
      file = peon.give(subfolder: schools_folder, file: file)
      parsed_page = parser.parse_html(file)
      data_hash = parser.school_data_parser(parsed_page, run_id, link)
      keeper.insert_school_data(data_hash)
    end
    keeper.finish
  end

  def store_baseball_data
    saved_files = peon.give_list(subfolder: box_scores_folder)
    logger.info "Found #{saved_files.count} files"
    saved_files.each do |file|
      next if ["2014-15_4_3", "2013-14_2_3"].include? file.gsub('.gz','')
      file_name = file.gsub(".gz","").gsub("_","/")
      file_name[-2] = "box"
      link = "https://ihsa.org/archive/ba/#{file_name}.htm"
      logger.info "#{file_name} -> #{link}"
      file = peon.give(subfolder: box_scores_folder, file: file)
      parsed_page = parser.parse_html(file)
      next if parsed_page.css("pre a").text.include?("Box Scores and Play by Play (PDF)") or parsed_page.text.include?("The page you are attempting to view has not been posted yet.")
      data_hash = parser.baseball_data_parser(parsed_page, run_id, link)
      keeper.insert_baseball_data(data_hash)
    end
    keeper.finish
  end

end
