require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper

  BASE_URL = "https://www.politico.com"
  OUTER_SUB_FOLDER = 'outer_politico'
  INNER_SUB_FOLDER = 'inner_politico'

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    index = 1

    loop do
        outer_file_name = "congress_#{index}"
        outer_response, _ = @scraper.get_request("#{BASE_URL}/congress/#{index}")        
        links = @parser.extract_links(outer_response.body)
        save_file(links.to_s, outer_file_name, OUTER_SUB_FOLDER)

        links.each do |link|
         # We are skipping any video links, as we only want to process textual info 
         if link.split("/")[3] == "news"
          @logger.info "Processing URL -> #{url}".yellow
          inner_file_name = Digest::MD5.hexdigest(link)
          inner_response, _ = @scraper.get_request(link)
          save_file(inner_response.body, inner_file_name, INNER_SUB_FOLDER)
         end     
        end

        links.length.zero? ? break : index += 1
    end                          
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      @logger.error e.full_message
    end
  end

  private

  def process_each_file
    @all_files = peon.give_list(subfolder: OUTER_SUB_FOLDER)

    @all_files.each do |file_name|
      file_path = peon.copy_and_unzip_temp(file: file_name , from: OUTER_SUB_FOLDER)  
      @links = read_file(file_path)
      @links.each do |link|
        if link.split("/")[3] == "news"
          file_name = Digest::MD5.hexdigest(link)
          file_content = peon.give(subfolder: INNER_SUB_FOLDER, file: file_name)
          @hash = @parser.parse_inner_page file_content , link
          @keeper.store(@hash)
        end
      end
    end
    
    @keeper.finish
  end

  def read_file(file_path)
    file = File.open(file_path).readlines
    link_list = file.map{|item| item[2..-3].split("\", \"")}
    link_list[0]
  end

  def save_file(content, file_name, sub_folder_type)
    peon.put content: content, file: "#{file_name}", subfolder: sub_folder_type
  end

end
