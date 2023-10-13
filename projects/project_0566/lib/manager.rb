# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper = Scraper.new
  end
  
  def download
    page_number = get_page_number
    response,cookie_value = get_cookie_value
    total_pages = parser.get_total_pages(response.body)
    while true
      break if (page_number > total_pages)
      response,cookie_value = get_cookie_value
      response = scraper.get_pagination_request(cookie_value, page_number)
      ids = parser.get_ids(response.body)
      downloaded_ids = get_downloaded_ids("#{keeper.run_id}/outer_page_#{page_number}")
      ids = ids.reject{ |id| downloaded_ids.include? id }
      save_page(response, "outer_page_#{page_number}", "#{keeper.run_id}/outer_page_#{page_number}") if ids.count > 1
      ids.each do |id|
        response = scraper.get_inner_request(id, cookie_value)
        page = parser.parse_page(response.body)
        if parser.captcha_page?(page)
          cookie_value = get_cookie_value
          response = scraper.get_pagination_request(cookie_value, page_number)
          ids = parser.get_ids(response.body)
        end
        file_name = id.scan(/([A-Za-z0-9]+)/).flatten.join
        save_page(response, file_name, "#{keeper.run_id}/outer_page_#{page_number}")
      end
      page_number += 1
    end
  end

  def store
    downloaded_folders = peon.list(subfolder: "#{keeper.run_id}")
    downloaded_folders.each do |folder|
      data_array = []
      downloaded_files = peon.give_list(subfolder: "#{keeper.run_id}/#{folder}")
      next unless downloaded_files.count > 1
      downloaded_files.each do |file|
        next unless file.include? 'outer'
        outer_page = peon.give(subfolder: "#{keeper.run_id}/#{folder}", file: file)
        ids,insurance,discpline = parser.get_outer_values(outer_page)
        ids.each_with_index do |id,index|
          inner_page = peon.give(subfolder: "#{keeper.run_id}/#{folder}", file: "#{id}.gz") rescue nil
          next if (inner_page.nil?)
          data_array << parser.parse_data(inner_page, id, insurance[index], discpline[index], keeper.run_id)
        end
      end
      md5_array = parser.get_md5_array(data_array)
      keeper.update_touch_id(md5_array)
      data_array = parser.delete_md5_key(data_array,:md5_hash)
      keeper.insert_records(data_array)
    end
    keeper.mark_delete
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def get_cookie_value
    response = scraper.get_main_request
    cookie_value = response.headers['set-cookie'].split("\;").first
    response = scraper.get_search_request(cookie_value)
    [response,cookie_value]
  end

  def get_page_number
    begin
      files = peon.list(subfolder: "#{keeper.run_id}")
      files = files.map{ |e| e.split('_').last.to_i }.sort.reverse.first
    rescue
      1
    end
    (files.nil?) ? 1 : files
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

  def get_downloaded_ids(path)
    begin
      files = peon.give_list(subfolder: path)
      files.reject{|e| e.include? 'outer'}.map{|e| e.gsub('.gz','')}
    rescue
      []
    end
  end

end
