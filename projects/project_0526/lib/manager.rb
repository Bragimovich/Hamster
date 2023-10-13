# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
    
  HOST = "https://mobar.org"
  BASE_URL = "https://mobar.org/site/content/For-the-Public/Lawyer_Directory.aspx"
  SUB_FOLDER = "lawyerDirectory"

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
    download_with_cities
    download_with_last_name
  end


  def download_with_cities
    main_page_response, status = @scraper.get(BASE_URL)
    @cookie = main_page_response.headers["set-cookie"]
    param_hash = @parser.get_required_form_data_variables(main_page_response.body)

    @all_cities = @keeper.all_cities
    @all_cities.each do |city|
      download_all_data(@cookie, param_hash, '', city)
    end
  end

  def download_with_last_name(last_name = '')
    main_page_response, status = @scraper.get(BASE_URL)
    @cookie = main_page_response.headers["set-cookie"]
    param_hash = @parser.get_required_form_data_variables(main_page_response.body)
    
    ('a'..'z').each do |letter_0|
      word = last_name + letter_0
      more_records_available = download_all_data(@cookie, param_hash, word, '')

      if more_records_available
        download_with_last_name(word)
      end
    end
  end
  
  def store
    process_each_file
    @keeper.finish
  end
  
  private

  def download_all_data(cookie, param_hash, last_name, city)
    param_hash[:last_name] = last_name
    param_hash[:city] = city
    response ,status = @scraper.post(BASE_URL, param_hash, @cookie)
    more_records_available = @parser.check_for_records_limit(response.body)
    get_all_data_from_paginated_page(response,last_name, city) if status == 200
    more_records_available
  end

  def get_all_data_from_paginated_page(response, last_name, city)
    link_divs = @parser.get_link_of_all_data(response.body)
    if link_divs.present?
      script_manager_for_getting_all_data = @parser.parse_all_data_div(link_divs&.first)
      param_hash = @parser.get_required_form_data_variables_v2(response.body)
      param_hash[:manager] = script_manager_for_getting_all_data
      param_hash[:last_name] = last_name
      param_hash[:city] = city
      response ,status = @scraper.post(BASE_URL, param_hash ,@cookie)
      download_inner_data(response) if status == 200
    else
      # only one page is there and (either results are there or not)
      # just save the passed response without getting all the data
      download_inner_data(response)
    end
  end
  
  def process_each_file
    @all_files = peon.give_list(subfolder: SUB_FOLDER).reject{|x| x.include?("page")}
    @all_files.each do |file_name|
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
      inner_url = @files_to_link[file_name[0..-4]]
      @hash = @parser.parse_user_page(file_content)
      @hash[:data_source_url] = inner_url
      @keeper.store(@hash)
    end
  end

  def download_inner_data(response)
    all_users = @parser.get_each_user_data(response.body)
    @all_file = peon.give_list(subfolder: SUB_FOLDER)
    all_users.each do |user|
      hash = @parser.get_user_hash(user)
      inner_url = HOST + hash[:link]
      file_name = Digest::MD5.hexdigest(inner_url)
      save_csv(file_name, inner_url)
      next if @all_file.include?(file_name + '.gz')
      response, status = @scraper.get(inner_url)
      save_file(response,file_name) if status == 200
    end
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def save_csv(file_name, link)
    unless @files_to_link.key?(file_name)
      rows = [[file_name , link]]
      @files_to_link[file_name] = link
      File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
    end
  end

end