require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require 'roo-xls'

class Manager < Hamster::Scraper

  SUB_FOLDER = 'FASFA_completion_school'
  STATES_DIRECTORY_NAME = "states"
  ARCHIVES_DIRECTORY_NAME = "archives"
  JSON_LINK = 'https://studentaid.gov/data-center/student/application-volume/fafsa-completion-high-school.json'
  BASE_URL = 'https://studentaid.gov'

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @dir_path = @_storehouse_ + 'filename_link.csv'
    @files_to_link = {}
    if File.file?(@dir_path)
      table = CSV.parse(File.read(@dir_path), headers: false)
      table.map{ |x| @files_to_link[x[0]] = x[1] }
    end
  end

  
  def download
    begin
      response ,status =  @scraper.download_main_json_file(JSON_LINK)
      return if status != 200
      # parse response body got from scrapper
      json_response = @parser.parse_main_json_file(response)
      states = @parser.get_all_states_file_links_from_json(json_response[0])
      archives = @parser.get_all_archives_file_links_from_json(json_response[1])
      # download and save state and archives xls files
      states.map{|state| download_and_save_xls_file(STATES_DIRECTORY_NAME , state[:link]) }
      archives.map{|archive| download_and_save_xls_file(ARCHIVES_DIRECTORY_NAME , archive[:link]) }
    rescue Exception => e
      puts e
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
    end
  end


  def store
    begin
      states_files = peon.give_list(subfolder: SUB_FOLDER + "/#{STATES_DIRECTORY_NAME}")
      states_files.each do |file_name|
        path = SUB_FOLDER + "/#{STATES_DIRECTORY_NAME}"
        file_path = peon.copy_and_unzip_temp(file: file_name , from: path)
        data_source_link = @files_to_link[file_name[0...-3]]
        result = @parser.parse_xls(file_path , data_source_link , false)
        @keeper.store_state(result)
      end

      archive_files = peon.give_list(subfolder: SUB_FOLDER + "/#{ARCHIVES_DIRECTORY_NAME}")
      archive_files.each do |file_name|
        path = SUB_FOLDER + "/#{ARCHIVES_DIRECTORY_NAME}"
        file_path = peon.copy_and_unzip_temp(file: file_name , from: path)
        data_source_link = @files_to_link[file_name[0...-3]]
        result = @parser.parse_xls(file_path , data_source_link , true)
        @keeper.store_archive(result)
      end
      # clearing trash folder
      peon.throw_trash()
      peon.throw_temps()
      @keeper.finish
    rescue Exception => e
      puts e
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def download_and_save_xls_file(directory_name, path)
    file_name = path.split('/')[-1]
    file_name = file_name.gsub(" ","")
    # creating xls_uri by attaching base url 
    uri = BASE_URL + path.gsub(" ","%20")
    # downloading uri 
    response_xls = @scraper.download_xls_file(uri)
    # saving response in a file
    peon.put(file: file_name , content: response_xls, subfolder: SUB_FOLDER+"/#{directory_name}")
    save_csv(file_name, uri)
  end

  def save_csv(file_name,link)
    rows = [[file_name , link ]]
    File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
  end

end