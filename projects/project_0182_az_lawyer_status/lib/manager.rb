require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper  = Scraper.new
    @subfolder = "Run_Id_#{@keeper.run_id}"
    @already_inserted_links = @keeper.already_fetched
  end

  def download
    url = "https://www.legalserviceslink.com/lawyers/search_by_location/"
    body = scraper.connect_to(url)
    states = parser.fetch_state(body)
    states.each do |state|
      page_no = 1
      @already_downloaded = peon.give_list(subfolder: @subfolder+"/"+state.scan(/\w+/).join()).reject{|e| e.include?"page"} rescue []
      while true
        url = "https://www.legalserviceslink.com/lawyers/search_by_location/#{state}/page:#{page_no}/"
        response = scraper.connect_to(url)
        document = parser.parse_page(response)
        break if document.text.squish.include? "Not Found Error:"
        save_file(response,"page_#{page_no}",state.scan(/\w+/).join())
        record = parser.lawyer_body(response)
        lawyers_links = record.map{|e| "https://www.legalserviceslink.com" + parser.get_lawyer_url(e)}
        lawyers_links.each do |link|
          file_name = Digest::MD5.hexdigest link
          next if @already_downloaded.include? file_name+".gz"
          file = scraper.connect_to(link)
          save_file(file, file_name, state.scan(/\w+/).join())
        end
        page_no += 1
      end
    end
  end

  def store
    already_inserted_md5_hashes = keeper.already_inserted_md5_hashes
    states = peon.list(subfolder: @subfolder)
    states.each do |state|
      files = peon.give_list(subfolder: @subfolder+"/"+state).reject{|e| e.exclude?"page"}
      files.each do|file|
        md5_hash_array = []
        page_response =  peon.give(file:file, subfolder: @subfolder+"/"+state)
        record  =  parser.lawyer_body(page_response)
        lawyers_links = record.map{|e| "https://www.legalserviceslink.com" + parser.get_lawyer_url(e)}
        names, sections, date_admitted = parser.get_lawyer_data(record)
        lawyers_links.each_with_index do |link, index|
          file_name = Digest::MD5.hexdigest link
          main_page =  peon.give(file:file_name+".gz", subfolder: @subfolder+"/"+state)
          data_hash = parser.get_data(main_page, names[index], date_admitted[index], sections[index], link, keeper.run_id)
          md5_hash_array << data_hash[:md5_hash]
          @already_inserted_links.delete link if @already_inserted_links.include? link
          next if already_inserted_md5_hashes.include? data_hash[:md5_hash]
          keeper.save_record(data_hash)
        end
        keeper.update_touched_runId(md5_hash_array)
      end
    end
    keeper.mark_delete
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def save_file(response, file_name, sub_folder)
    peon.put content:response, file: file_name.to_s, subfolder: @subfolder +"/"+ sub_folder
  end
end
