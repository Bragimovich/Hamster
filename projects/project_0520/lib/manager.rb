require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require 'pry'

class Manager < Hamster::Scraper
  BASE_URL = "https://www.ihsa.org"
  SUB_FOLDER = 'schoolDirectory'

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    outer_url = BASE_URL + '/Schools/School-Directory'
    outer_page_response , status = @scraper.download_page(outer_url)
    return if status != 200
    file_name = Digest::MD5.hexdigest(outer_url)
    save_file(outer_page_response, file_name)
    all_hrefs = @parser.get_all_hrefs_of_outer_page(outer_page_response.body)
    all_hrefs.each do |ahref|
      if ahref.attributes["href"].present?
        inner_link = BASE_URL + ahref.attributes["href"].value
        file_name = Digest::MD5.hexdigest(inner_link)
        inner_page_response, status = @scraper.download_page(inner_link)
        save_file(inner_page_response, file_name) if status == 200

        url = @parser.get_inner_url_from_dom(inner_page_response.body)
        inner_page_url = BASE_URL + url.to_s
        file_name = Digest::MD5.hexdigest(inner_page_url)
        page_response, status = @scraper.download_page(inner_page_url)
        save_file(page_response , file_name) if status == 200

        schools = @parser.get_all_schools(page_response.body)

        schools.each do |school|
          school_url = BASE_URL + '/data/school/' + school['href']
          school_page_response, status = @scraper.download_page(school_url)
          file_name = Digest::MD5.hexdigest(school_url)
          save_file(school_page_response,file_name) if status == 200
        end
      end
    end
    # download cooperative_Teams page
    cooperative_team_url = BASE_URL + '/Schools/School-Directory/Cooperative-Teams'
    cooperative_team_page_response, status = @scraper.download_page(cooperative_team_url)
    file_name = Digest::MD5.hexdigest(cooperative_team_url)
    save_file(cooperative_team_page_response,file_name) if status == 200

    url = @parser.get_inner_url_from_dom(cooperative_team_page_response.body)
    inner_page_url = BASE_URL + url.to_s
    file_name = Digest::MD5.hexdigest(inner_page_url)
    page_response, status = @scraper.download_page(inner_page_url)
    save_file(page_response , file_name) if status == 200
  end

  def store
    begin
      process_each_file
      @keeper.finish
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  def process_each_file
    outer_url = BASE_URL + '/Schools/School-Directory'
    outer_file_name = Digest::MD5.hexdigest(outer_url)
    file_content = peon.give(subfolder: SUB_FOLDER, file: outer_file_name)
    all_hrefs = @parser.get_all_hrefs_of_outer_page(file_content)
    all_hrefs.each do |ahref|
      if ahref.attributes["href"].present?
        inner_link = BASE_URL + ahref.attributes["href"].value
        file_name = Digest::MD5.hexdigest(inner_link)
        file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)

        url = @parser.get_inner_url_from_dom(file_content)
        inner_page_url = BASE_URL + url.to_s
        file_name = Digest::MD5.hexdigest(inner_page_url)

        file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
        schools = @parser.get_all_schools(file_content)

        schools.each do |school|
          school_url = BASE_URL + '/data/school/' + school['href']
          file_name = Digest::MD5.hexdigest(school_url)
          file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
          hash = @parser.get_address(file_content)
          hash['data_source_url'] = school_url
          hash['short_name'] = school&.text&.encode("UTF-8", invalid: :replace, replace: "")&.squish
          @keeper.store_school_info(hash)
          division_list = @parser.get_all_divison(file_content)
          @keeper.store_school_departments(division_list.map{|x| {division: x}})

          list = @parser.get_school_directors(file_content)
          school_id = @keeper.get_school_info_id(school_url)

          list&.each do |l|
            division_id = @keeper.get_department_id(l.first)
            list_of_hashes = @parser.parse_school_directors(l)
            list_of_hashes.each do |l|
              l['school_id'] = school_id
              l['division_id'] = division_id
              l['data_source_url'] = school_url
            end
            @keeper.store_school_directors(list_of_hashes)
          end
        end
      end
    end
    # store cooperative teams
    store_school_cooperative_teams
  end

  private

  def store_school_cooperative_teams
    cooperative_team_url = BASE_URL + '/Schools/School-Directory/Cooperative-Teams'
    file_name = Digest::MD5.hexdigest(cooperative_team_url)
    file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)

    url = @parser.get_inner_url_from_dom(file_content)
    file_name = Digest::MD5.hexdigest(BASE_URL + url.to_s)
    file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)

    list_of_sports = @parser.get_all_sports(file_content)
    @keeper.store_school_sports(list_of_sports.map{ |x| {sport_name: x} })
    sports_tables_hash = @parser.get_all_tables(file_content)

    sports_tables_hash.keys.each do |sport_name|
      sport_id = @keeper.get_school_sport_id(sport_name)
      list_of_hashes = @parser.parse_sports_table(sports_tables_hash[sport_name])
      list_of_hashes.each do |hash|
        host_school_id = @keeper.get_school_info_id_by_school_name(hash[:host_school_name])
        hash[:host_school_id] = host_school_id
        opponent_school_id = @keeper.get_school_info_id_by_school_name(hash[:opponent_school_name])
        hash[:opponent_school_id] = opponent_school_id
        hash[:sport_id] = sport_id
        hash[:data_source_url] = cooperative_team_url
        # store school info and sport_id
        @keeper.store_school_type_and_school_info({ihsa_school_sports_type_id: sport_id,ihsa_school_info_id: host_school_id})
        @keeper.store_school_type_and_school_info({ihsa_school_sports_type_id: sport_id,ihsa_school_info_id: opponent_school_id})
        # delete extra keys
        hash.delete(:host_school_name)
        hash.delete(:opponent_school_name)
      end
      @keeper.store_school_cooperative_teams(list_of_hashes)
    end
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

end