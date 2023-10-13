# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester

  MAIN_URL = "https://docpub.state.or.us/OOS/searchCriteria.jsf"

  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = keeper.run_id
    @offender_data_folder = "Offender_Data"
  end

  def download
    FileUtils.rm_rf Dir.glob("#{storehouse}/store/#{offender_data_folder}")
    ("aaa".."zzz").to_a.each do |letters|
      offender_id = ""
      more_offender_flag = false
      cookie, js_viewState = get_cookie_and_js_view_states
      response = scraper.search_request(letters, cookie, js_viewState, offender_id, more_offender_flag)
      parsed_page = parser.parse_html(response.body)
      save_current_offender(letters, cookie, js_viewState, parsed_page, more_offender_flag)
      no_match_found, info_message = parser.get_match_result(parsed_page)
      logger.info "************** #{info_message} For #{letters} **************"
      if no_match_found and info_message.include?("Too many results to display. Be more specific.")
        logger.info "************** #{info_message} For #{letters} **************"
        ("a".."z").to_a.each do |letter_2|
          final_letters = letters + letter_2
          response = scraper.search_request(final_letters, cookie, js_viewState, offender_id, more_offender_flag)
          parsed_page = parser.parse_html(response.body)
          save_current_offender(final_letters, cookie, js_viewState, parsed_page, more_offender_flag)
          no_match_found, info_message = parser.get_match_result(parsed_page)
          if no_match_found
            logger.info "************** #{info_message} For #{final_letters} **************"
            next
          end
          next_flag = get_more_offerder(parsed_page, final_letters, cookie, js_viewState, offender_id, more_offender_flag)
          next if next_flag
        end
      end
      next_flag = get_more_offerder(parsed_page, letters, cookie, js_viewState, offender_id, more_offender_flag)
      next if next_flag
    end
    logger.info "********* Donwload Done *********"
  end

  def store
    saved_files = peon.give_list(subfolder: offender_data_folder)
    logger.info "Found #{saved_files.count} files"
    saved_files.each do |file|
      logger.info "******** Processing File #{file} *******"
      file = peon.give(subfolder: offender_data_folder, file: file)
      parsed_page = parser.parse_html(file)
      data_hash = parser.get_offender_data(parsed_page)
      keeper.insert_all_data(data_hash)
      keeper.update_touch_run_id
    end
    keeper.mark_deleted
    keeper.finish
    logger.info "******** Store Done *******"
  end
  
  def cron
    logger.info "******** Cron Started *******"
    download
    logger.info "******** Download Done *******"
    store
    logger.info "******** Cron Done *******"
  end

  private 
  attr_accessor  :scraper, :parser, :run_id, :keeper, :offender_data_folder

  def get_cookie_and_js_view_states
    response = scraper.main_request
    parsed_page = parser.parse_html(response.body)
    cookie = response.headers["set-cookie"]
    js_viewState = parser.get_view_states(parsed_page)
    [cookie, js_viewState]
  end

  def save_file(response, file_name, folder)
    peon.put content: response.body, file: file_name, subfolder: folder
  end

  def save_current_offender(letters, cookie, js_viewState, parsed_page, more_offender_flag)
    offenders_id_array = parser.get_offenders(parsed_page)
    offenders_id_array.each do |offender|
      logger.info "********* #{letters} || #{offender["sid_num"]} *********"
      file_name = offender["sid_num"]
      response = scraper.search_request(letters, cookie, js_viewState, offender["j_id"], more_offender_flag)
      save_file(response, file_name, offender_data_folder)
      logger.info "********* File Saved *********"
    end
  end

  def get_more_offerder(parsed_page, letters, cookie, js_viewState, offender_id, more_offender_flag)
    more_offender_flag, num_of_pages = parser.check_for_more_offenders(parsed_page)
    if more_offender_flag  
      (2..num_of_pages).to_a.each do |num|
        logger.info "************** Total Num Of Pages #{num_of_pages} For #{letters} On Page #{num} **************"
        response = scraper.search_request(letters, cookie, js_viewState, offender_id, more_offender_flag)
        parsed_page = parser.parse_html(response.body)
        no_match_found, info_message = parser.get_match_result(parsed_page)
        if no_match_found
          logger.info "********* #{info_message} *********"
        else
          save_current_offender(letters, cookie, js_viewState, parsed_page, more_offender_flag)
        end
        return true if num == num_of_pages
      end
    end 
  end

end

