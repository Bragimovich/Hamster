require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require 'pry'

class Manager < Hamster::Scraper

  SUB_FOLDER = 'policeDepartments'
  BASE_URL = "https://www.police1.com"

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
    @all_file = peon.give_list(subfolder: SUB_FOLDER)
    response ,status = @scraper.get_request(BASE_URL + '/law-enforcement-directory/search/')
    @all_states = @parser.get_all_states(response.body)
    @all_states.each do |state|
      url = BASE_URL + "/law-enforcement-directory/search/#{state}"
      download_all_pages(url, state)
    end
    # For all states
    url = BASE_URL + "/law-enforcement-directory/search/"
    download_all_pages(url, '')
  end

  def download_all_pages(url, state='')
    @all_file = peon.give_list(subfolder: SUB_FOLDER)
    page_count = 1
    records = []
    while true
      url_with_page_number = url + "/page-#{page_count}/"

      response ,status = @scraper.get_request(url_with_page_number)
      break if status == 404
      
      rows = @parser.get_table_rows(response.body)
      rows.each do |row|
        relative_uri = @parser.get_url_from_row(row)
        file_name = Digest::MD5.hexdigest(relative_uri)
        next if @all_file.include?(file_name + '.gz')
        save_csv(file_name, BASE_URL + relative_uri)
        inner_response ,status = @scraper.get_request(BASE_URL + relative_uri)
        next if status != 200
        save_file(inner_response,file_name)
      end
      save_file(response,"#{state}_page#{page_count}")
      page_count += 1
    end
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def process_each_file
    @all_files = peon.give_list(subfolder: SUB_FOLDER)
    @all_files = @all_files.select{|x| x.include?("page") }
    @all_files.each do |file_name|
      puts "Parsing file #{file_name}".yellow
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
      rows = @parser.get_table_rows(file_content)
      rows.each do |row|
        relative_uri = @parser.get_url_from_row(row)
        file_name = Digest::MD5.hexdigest(relative_uri)
        puts "Processing Inner link #{relative_uri}".blue
        inner_file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
        info ,additional_info = @parser.get_info_from_details_page(inner_file_content)
        @hash = @parser.get_info_from_hash(info)
        @hash2 = @parser.get_info_from_hash(additional_info)
        @hash['data_source_url'] = BASE_URL + relative_uri
        @hash.merge!(@hash2)
        # replace the key name zip_code in hash with zip
        @hash['zip'] = @hash.delete('zip_code') if @hash.key?('zip_code')
        @hash['phone_number'] = @hash.delete('phone') if @hash.key?('phone')

        title = @parser.get_title_from_from_page(inner_file_content)
        title, *location = title.split("-")
        @hash['name'] = title.strip
        @hash['location'] = location.join(" ").strip
        @hash['fax_number'] = @hash.delete('fax') if @hash.key?('fax')
        @keeper.store(@hash)
      end
    end
    @keeper.finish
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def save_csv(file_name, link)
    unless @files_to_link.key?(link)
      rows = [[file_name , link]]
      File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
    end
  end

end
