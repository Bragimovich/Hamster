require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  BASE_URL = "https://www.mywsba.org/PersonifyEbusiness/LegalDirectory.aspx"
  BASE_URL_FOR_USER_PROFILE = "https://www.mywsba.org/PersonifyEbusiness/LegalDirectory/LegalProfile.aspx"
  SUB_FOLDER = 'lawyerStatus152'
  MAX_RESULT_COUNT = 20

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @dir_path = @_storehouse_ + 'filename_link.csv'
    @files_to_link = {}
    @lawyer_to_city = {}
    @outer_downloaded_pages = {}
    if File.file?(@dir_path)
      table = CSV.parse(File.read(@dir_path), headers: false)
      table.map{ |x| @files_to_link[x[0]] = x[1] }
      table.map{ |x| @lawyer_to_city[x[0]] = x[2] }
    end
  end
    
  def download
    ('a'..'z').to_a.each do |char|
      link = BASE_URL + "?ShowSearchResults=TRUE&FirstName=#{char}"
      response , status = @scraper.download_page(link)
      next if status != 200
      user_ids, cities = @parser.get_all_user_ids(response.body) 
      download_user_ids(user_ids, cities)
      total_result_count = @parser.get_results_count(response.body)
      total_pages = total_result_count / MAX_RESULT_COUNT
      (1..total_pages).each do |page|
        link = BASE_URL + "?ShowSearchResults=TRUE&FirstName=#{char}&page=#{page}"
        response , status = @scraper.download_page(link)
        next if status != 200
        user_ids, cities = @parser.get_all_user_ids(response.body) 
        download_user_ids(user_ids, cities)
      end
    end
  end

  def store
    process_each_file
    @keeper.finish
  end

  def process_each_file
    @all_files = peon.give_list(subfolder: SUB_FOLDER).select{|x| x.include?("user")}
    @all_files.each do |file_name|
      inner_page_url = @files_to_link[file_name]
      if inner_page_url.present?
        file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
        hash = @parser.parse_lawyer(file_content)
        hash[:link] = inner_page_url
        hash[:law_firm_city] = @lawyer_to_city[file_name]
        @keeper.store(hash)
      end
    end
  end

  private

  def download_user_ids(user_ids, cities)
    if user_ids.present?
      user_ids.each_with_index do |user_id, index|
        link = BASE_URL_FOR_USER_PROFILE + "?Usr_ID=#{user_id}"
        file_name = 'user_id_' + Digest::MD5.hexdigest(link) + '.gz'
        response , status = @scraper.download_page(link)
        next if status != 200
        save_file(response, file_name)
        save_csv(file_name, link, cities[index])
        # unless @files_to_link[file_name].present?
        # end
      end
    end
  end


  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def save_csv(file_name, link, city)
    unless @files_to_link.key?(link)
      rows = [[file_name , link, city]]
      File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
    end
  end
end
