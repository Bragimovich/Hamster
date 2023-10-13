# frozen_string_literal: true
require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  COOKIE_ATTRIBUTES = ['EDLFDCVM','ASP.NET_SessionI','.ASPXFORMSPUBLICACCESS']
  def initialize
    super
    @host = 'https://ccmspa.pinellascounty.org'
    @start_uri = '/PublicAccess/default.aspx'
    @date_from = "01/01/2018"
    @search_url =  'https://ccmspa.pinellascounty.org/PublicAccess/Search.aspx?ID=300&NodeID=11000,11100,23001,11101,11102,11103,11104,11105,11106,11107,11108,11114,11109,23002,23003,11110,11111,11112,11113,11200,11201,11202,11203,11204,11205,11206,11207,11208,23004,11209,11210,11300,11301,11302,11303,11304,11305,11400,11410,11411,11412,11450,11451,11452,11453,11600,11601,11602,11603,11604,12000,12100,12101,12102,12103,12104,12105,12106,12107,12108,12109,12110,12111,12113,12112,12114,12200,12201,12202,12203,12204,12205,12206,12207,12208,12209,12300,12310,12311,12312,12320,12321,12322,12400,14000,14100,14200,14300,14400,14500,14600,13000,13100,13200&NodeDesc=Pinellas%20County' 
  end

  def start_url
    url = "#{host}#{start_uri}"
  end
  
  def download_page(link)
    response = nil
    10.times do
      headers_search = headers_search_get(@cookie)
      response = Hamster.connect_to("#{@host}/PublicAccess/#{link}", headers: headers_search)
      reporting_request response
      
      break if [200,301,304,308,307].include?(response&.status)
    end
    response&.body
  end

  def search_cases(search_character)
    response = nil
    @cookie = get_cookie
    10.times do
      headers_search = headers_search_get(@cookie)
      response = Hamster.connect_to(@search_url, headers: headers_search)
      reporting_request response
      viewstate, viewstategenerator, eventvalidation = Parser.new.view_state_params(response&.body)

      next if viewstate.nil?
      # retry next
      @cookie += "; " + filter_cookies(response&.headers['set-cookie']) if response&.headers['set-cookie']
      body = req_body(viewstate, viewstategenerator, eventvalidation, search_character)
      headers_search = headers_search_post(@cookie)
      response = Hamster.connect_to(@search_url, headers: headers_search, method: :post, req_body: body)
      reporting_request response
      break if [200,301,304,308,307].include?(response&.status)
    end
    response&.body
  end

  def download_pdf(link)
    @cookie ||= get_cookie
    response = nil
    
    10.times do
      headers = pdf_headers(@cookie)
      response = Hamster.connect_to("#{@host}/PublicAccess/#{link}", headers: headers)
      reporting_request response
      
      break if [200,301,304,308,307].include?(response&.status)
    end
    
    unless response&.headers["content-disposition"].nil?
      logger.debug 'successfully downloaded file'
      response&.body 
    end
  end

  def absolute_url(link)
    link = "#{@host}/PublicAccess/#{link}" unless link.start_with?('http')

    link
  end

  def get_cookie
    url = 'https://ccmspa.pinellascounty.org/PublicAccess/Login.aspx'
    response = Hamster.connect_to(url,headers: req_headers)
    reporting_request response
    cookie = filter_cookies(response&.headers['set-cookie'])
    cookie
  end

  private

  attr_accessor :host, :start_uri

  def filter_cookies(cookie)
    cookie = cookie.gsub('path=/;','').gsub('Secure,','').gsub(' Secure','').gsub('HttpOnly;','').gsub('.ASPXFORMSPUBLICACCESS=;','')
    cookie = cookie.gsub('expires=Tue, 12-Oct-1999 04:00:00 GMT;','').gsub(/; expires.+$/,'').squeeze(' ').strip
  end

  def pdf_headers(cookies)
    {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Encoding': 'gzip, deflate, br',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
      'Host': 'ccmspa.pinellascounty.org',
      'Sec-Fetch-Dest': 'document',
      'Cookie': cookies
    }
  end

  def req_headers
    {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
      'Host': 'ccmspa.pinellascounty.org'
    }
  end

  def headers_search_post(cookies)
    req_headers.merge({
      'Content-Type' => 'application/x-www-form-urlencoded',
      "Cookie" => cookies,
      "Origin" => "https://ccmspa.pinellascounty.org",
      "Referer" => @search_url
    })
  end

  def headers_search_get(cookies)
    req_headers.merge({"Cookie" => cookies})
  end

  def reporting_request(response)
    logger.debug '=================================='
    logger.debug 'Response status: '.indent(1, "\t")
    status = response&.status
    logger.debug status.to_s
    logger.debug '=================================='
  end

  def search_params c
    {
      "SearchBy"=>"1",
      "ExactName"=>"on",
      "CaseSearchMode"=>"CaseNumber",
      "CaseSearchValue"=>"",
      "CitationSearchValue"=>"",
      "CourtCaseSearchValue"=>"",
      "PartySearchMode"=>"Name",
      "AttorneySearchMode"=>"Name",
      "LastName"=>"#{c}",
      "FirstName"=>"",
      "cboState"=>"AA",
      "MiddleName"=>"",
      "DateOfBirth"=>"",
      "DriverLicNum"=>"",
      "CaseStatusType"=>"0",
      "DateFiledOnAfter"=> "#{@date_from}",
      "DateFiledOnBefore" => "",
      "chkCriminal" => "on",
      "chkFamily" => "on",
      "chkCivil" => "on",
      "chkProbate" => "on",
      "chkDtRangeCriminal" => "on",
      "chkDtRangeFamily" => "on",
      "chkDtRangeCivil"=>"on",
      "chkDtRangeProbate"=>"on",
      "chkCriminalMagist"=>"on",
      "chkFamilyMagist"=>"on",
      "chkCivilMagist"=>"on",
      "chkProbateMagist"=>"on",
      "DateSettingOnAfter"=>"",
      "DateSettingOnBefore"=>"",
      "SortBy"=>"fileddaterev",
      'g-recaptcha-response' => solve_captcha,
      # 'g-recaptcha-response' => 'solve_captcha',
      "SearchType"=>"PARTY",
      "SearchMode"=>"NAME",
      "NameTypeKy"=>"ALIAS",
      "BaseConnKy"=>"",
      "StatusType"=>'true',
      "ShowInactive"=>"",
      "AllStatusTypes"=>'true',
      "CaseCategories"=>"",
      "RequireFirstName"=>'false',
      "CaseTypeIDs"=>"",
      "HearingTypeIDs"=>"",
      "SearchParams"=> "Party~~Search By:~~1~~Party||chkExactName~~Exact Name:~~on~~on||PartyNameOption~~Party Search Mode:~~Name~~Name||LastName~~Last Name:~~a~~a||DateFiledOnAfter~~Date Filed On or After:~~#{@date_from}~~#{@date_from}||selectSortBy~~Sort By:~~Filed Date Rev~~Filed Date Rev"
    }
  end

  def req_body(viewstate, viewstategenerator, eventvalidation, last_name)
    event_state_params = {
      '__EVENTTARGET' => '',
      '__EVENTARGUMENT' => '',
      '__VIEWSTATE' => viewstate,
      '__VIEWSTATEGENERATOR' => viewstategenerator,
      '__EVENTVALIDATION' => eventvalidation
    }
    form_data = search_params(last_name).merge(event_state_params)

    req_body = form_data.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    
  end

  def url_decode(item)
    item.gsub('/','%2F').gsub('=','%3D').gsub('+','%2B').gsub(',','%2C').gsub('~','%7E').gsub('|','%7C').gsub(':','%3A').gsub(' ','+')
  end

  def solve_captcha
    options = {
      pageurl: @search_url,
      googlekey: '6Ldr5O8gAAAAAPyOjXwE-r02YXYplxTFh35DD27a'
    }
    captcha_client = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)

    money = captcha_client.balance
    logger.debug "#{money}"
    if money < 1
      Hamster.report(to: 'Jaffar Hussain', message: 'Project #652 2captcha balance < 1')
      return nil
    end

    decoded_captcha = captcha_client.decode_recaptcha_v2!(options)
    
    decoded_captcha.text
    rescue StandardError => e
      logger.error e
      Hamster.report(to: 'Jaffar Hussain', message: "Project #652 solve_captcha:\n#{e}")
      nil
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end
end
