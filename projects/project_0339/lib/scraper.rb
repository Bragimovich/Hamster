# frozen_string_literal: true

require 'json'
require_relative 'parser'
require_relative '../module/slack_custom'
require_relative '../models/north_carolina_business_licenses_new_business_csv'
require_relative '../models/north_carolina_business_licenses_csv_files_by_year'

class Scraper < Hamster::Scraper
  include SlackCustom

  def initialize
    super
    @parser = Parser.new
  end

  def download_csv
    search_type = ["NEW", "Dis"]
    search_type.each do |type|
      download_new_and_dissolved_csv_by_date(type)
    end
  end

  private

  def download_csv_file(url, csv_file_name)
    logger.debug '===START download_csv_file==='
    proxy = Camouflage.new(local_chrome: true)
    current_proxy = nil
    1.upto(100) do |i|
      current_proxy = proxy.swap
      logger.debug current_proxy
      break unless current_proxy.include? 'socks'
    end
    raise 'No http proxy found' if current_proxy.include? 'socks'
    File.write "#{storehouse}/store/#{csv_file_name}", open(url, { proxy: current_proxy }).read
    logger.debug '===END download_csv_file==='
    true
  end

  def download_new_and_dissolved_csv_by_date(type)

    if type == "NEW"
      now = Date.today
      three_month_back = now << 3
      from_day = three_month_back.day.to_s.rjust(2, '0')
      from_month = three_month_back.month.to_s.rjust(2, '0')
      from_year = three_month_back.year    
      to_day = now.day.to_s.rjust(2, '0')
      to_month = now.month.to_s.rjust(2, '0')
      to_year = now.year
    else
      now = Date.today
      six_month_back = now << 6
      from_day = six_month_back.day.to_s.rjust(2, '0')
      from_month = six_month_back.month.to_s.rjust(2, '0')
      from_year = six_month_back.year
      three_month_back = now << 3
      to_day = three_month_back.day.to_s.rjust(2, '0')
      to_month = three_month_back.month.to_s.rjust(2, '0')
      to_year = three_month_back.year
    end


    headers = {
      accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      accept_language: 'en-US,en;q=0.5',
      connection: 'keep-alive',
      upgrade_insecure_requests: '1',
      'X-Requested-With': 'XMLHttpRequest',
      referer: 'https://find.pitt.edu/',
    }
    response = connect_to(url: 'https://www.sosnc.gov/online_services/search/by_title/_Business_Registration_Changes',
                          headers: headers,
                          method: :get)

    logger.debug response
    logger.debug response.body

    logger.debug "===START req_verification_token==="
    logger.debug req_verification_token = response.headers['set-cookie'].split(';')[10].split(',').last.strip
    logger.debug "===END req_verification_token==="
    logger.debug "===START req_verification_token_clear==="
    logger.debug req_verification_token_clear = req_verification_token.gsub('__RequestVerificationToken=', '')
    logger.debug "===END req_verification_token_clear==="
    logger.debug "===START req_verification_token_html==="
    logger.debug req_verification_token_html = @parser.parse_req_ver_token(response.body)
    logger.debug "===END req_verification_token_html==="
    logger.debug "===START session_id==="
    logger.debug session_id = response.headers['set-cookie'].split(';').first
    logger.debug "===END session_id==="

    headers = {
      accept: '*/*',
      accept_language: 'en-US,en;q=0.5',
      connection: 'keep-alive',
      'X-Requested-With': 'XMLHttpRequest',
      referer: 'https://www.sosnc.gov/online_services/search/by_title/_Business_Registration_Changes',
      'Accept-Encoding': 'gzip,deflate,br',
      'Content-Length': '266',
      'Host': 'www.sosnc.gov',
      'Origin': 'https://www.sosnc.gov',
      'Dnt': '1',
      'Cookie': "#{session_id}; #{req_verification_token}",
      'data-raw': "__RequestVerificationToken=#{req_verification_token_html}&FullSite=False&Action=Download&AboutSave=_Business_Registration_Changes&SearchType=#{type}&FromDate=#{from_month}%2F#{from_day}%2F#{from_year}&ToDate=#{to_month}%2F#{to_day}%2F#{to_year}&ProfileTypeIds=0&Counties=ALL"
    }

    req_body = "__RequestVerificationToken=#{req_verification_token_html}&FullSite=False&Action=Download&AboutSave=_Business_Registration_Changes&SearchType=#{type}&FromDate=#{from_month}%2F#{from_day}%2F#{from_year}&ToDate=#{to_month}%2F#{to_day}%2F#{to_year}&ProfileTypeIds=0&Counties=ALL"

    validation_response = connect_to(url: 'https://www.sosnc.gov/online_services/Search/Business_Registration_Changes_Results_Validation',
                                     req_body: req_body,
                                     headers: headers,
                                     method: :post)
    logger.debug ('*' * 100).green
    logger.debug validation_response
    logger.debug validation_response.body
    logger.debug ('-' * 100).green

    logger.debug '===Business_Registration_Changes_Results_Validation==='

    headers = {
      accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      accept_language: 'en-US,en;q=0.5',
      connection: 'keep-alive',
      referer: 'https://www.sosnc.gov/online_services/search/by_title/_Business_Registration_Changes',
      'Origin': 'https://www.sosnc.gov',
      'Dnt': '1',
      'Cookie': "#{session_id}; #{req_verification_token}",
      'Upgrade-Insecure-Requests': '1',
      'data-raw': "__RequestVerificationToken=#{req_verification_token_html}&FullSite=False&Action=Download&AboutSave=_Business_Registration_Changes&SearchType=#{type}&FromDate=#{from_month}%2F#{from_day}%2F#{from_year}&ToDate=#{to_month}%2F#{to_day}%2F#{to_year}&ProfileTypeIds=0&Counties=ALL"
    }

    logger.debug ('=' * 100).yellow
    logger.debug headers
    logger.debug ('=' * 100).yellow

    search_response = connect_to(url: 'https://www.sosnc.gov/online_services/Search/Business_Registration_Changes_Results',
                                 req_body: req_body,
                                 headers: headers,
                                 method: :post)

    logger.debug search_response
    logger.debug search_response.body

    logger.debug '===Business_Registration_Changes_Results==='
    return false if @parser.csv_records_not_found?(search_response.body)


    headers = {
      accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      accept_language: 'en-US,en;q=0.5',
      connection: 'keep-alive',
      referer: 'https://www.sosnc.gov/online_services/Search/Business_Registration_Changes_Results',
      'Origin': 'https://www.sosnc.gov',
      'Dnt': '1',
      'Cookie': "#{session_id}; #{req_verification_token}",
      'Upgrade-Insecure-Requests': '1',
      'data-raw': "Id=#{@parser.parse_csv_file_link(search_response.body)}"
    }

    req_body = "Id=#{@parser.parse_csv_file_link(search_response.body)}"

    download_response = connect_to(url: 'https://www.sosnc.gov/online_services/imaging/download_file',
                                 req_body: req_body,
                                 headers: headers,
                                 method: :post)
    logger.debug download_response
    logger.debug download_response.body
    logger.debug JSON.parse(download_response.body)
    logger.debug csv_file_name = JSON.parse(download_response.body)["fileName"].gsub('|', '%7C')
    logger.debug csv_file_url = "https://www.sosnc.gov/online_services/imaging/download/#{csv_file_name}"
    logger.debug local_csv_file_name = "nk_#{type}_business_licenses_year_#{to_year}.csv"
    logger.debug "===FINISH download_csv_by_year==="

    download_csv_file(csv_file_url, local_csv_file_name)

  end
end
