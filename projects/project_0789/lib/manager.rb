# # frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    ('aa'..'zz').each do |letter|
      info_hash = {}
      inmate_info_hash = []
      @first_letter = letter[0]
      @last_letter = letter[1]
      logger.debug ('*' * 100).green
      logger.debug "Scraping data for First name: #{@first_letter}, and Last name #{@last_letter}"
      logger.debug ('*' * 100).green
      response = @scraper.fetch_main_page
      cookie = response.headers["set-cookie"]
      token = @parser.get_access_token(response)
      solved_captcha = captcha_solver
      response = @scraper.captcha_verify(solved_captcha,token, cookie)
      old_cookie = cookie
      cookie = response.headers["set-cookie"]
      new_cookie = old_cookie + ";#{cookie.split(";").first};"
      response = @scraper.search_request(@first_letter,@last_letter,token,new_cookie,solved_captcha)
      doc = Nokogiri::HTML(response.body)
      tr_array = doc.css('body').css('div#masthead').css('tbody').css('tr')
      id_array = []
      tr_array.each do |tr|
        id_array << tr.at('a')['id']
        id_array
      end
      id_array.each do |id|
        response = @scraper.search_booking(id,token,cookie)
        doc1 = Nokogiri::HTML(response.body)
        tbody_1 = doc1.css('body').css('div#masthead').css('tbody')[0].css('tr')
        booking_id = doc1.css('body').css('div#masthead').css('tbody')[1].css('tr')[0].css('input').last['data-id']
        response = @scraper.search_detail(id,booking_id,token,cookie)
        doc2 = Nokogiri::HTML(response.body)
        info_hash['inmate_table'] = @parser.fetch_table_data(tbody_1,id)
        info_hash['inmate_booking'] = @parser.fetch_booking(doc2)
        info_hash['inmate_details'] = @parser.fetch_details(doc2)
        inmate_info_hash << info_hash
        booking_number = @parser.fetch_booking_number(doc1)
        logger.debug ('*' * 100).green
        logger.debug "Inserting data to database for First name: #{@first_letter}, Last name #{@last_letter} and id: #{id}"
        logger.debug ('*' * 100).green
        @keeper.parse_data(inmate_info_hash, booking_number)
        logger.debug ('*' * 100).green
        logger.debug "Data inserted to database for First name: #{@first_letter}, Last name #{@last_letter} and id: #{id}"
        logger.debug ('*' * 100).green
      end
    end
  end

  def captcha_solver( retries = 3)
    two_captcha = TwoCaptcha.new(Storage.new.two_captcha['general'], timeout:200, polling:5)
    logger.debug "Balance is -> #{two_captcha.balance}"
    options = {
      pageurl: "https://jailpublic.westchestergov.com/jailpublic",
      googlekey: '6LfLkk8UAAAAAPefQVTcmnjRKQDZRudOsC1ZoUK0'
    }
    begin
      decoded_captcha = two_captcha.decode_recaptcha_v2!(options)
      decoded_captcha.text
    rescue StandardError => e
      logger.debug e.full_message
      raise if retries <= 1
      captcha_solver(token, retries - 1)
    end
  end
end
