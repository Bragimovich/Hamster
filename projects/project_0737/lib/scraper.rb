# frozen_string_literal: true
require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  DATA_SOURCE_URL = 'http://inmateinfo.indy.gov/IML'
  CONNECTION_ERROR_CLASSES = [
    ActiveRecord::ConnectionNotEstablished,
    Mysql2::Error::ConnectionError,
    ActiveRecord::StatementInvalid,
    ActiveRecord::LockWaitTimeout
  ]
  def initialize
    super
  end

  def download_search(first_name='',last_name='')
    response = nil
    
    10.times do
      headers = req_headers.merge(search_headers(@cookie))
      response = Hamster.connect_to(DATA_SOURCE_URL, headers: headers,method: :post, req_body: search_req_body(first_name,last_name))
      reporting_request response
      
      break if [200,301,304,308,307].include?(response&.status)
    end
    
    response&.body 
  end

  def download_next(current_start)
    response = nil
    logger.debug "downloading next page"
    10.times do
      headers = req_headers.merge(search_headers(@cookie))
      response = Hamster.connect_to(DATA_SOURCE_URL, headers: headers,method: :post, req_body: next_req_body(current_start))
      reporting_request response
      
      break if [200,301,304,308,307].include?(response&.status)
    end
    
    response&.body 
  end

  def download_inmate(sys_id,img_sys_id)
    response = nil
    logger.debug "downloading inmate"
    10.times do
      headers = req_headers.merge(search_headers(@cookie))
      response = Hamster.connect_to(DATA_SOURCE_URL, headers: headers,method: :post, req_body: inmate_req_body(sys_id,img_sys_id))
      reporting_request response
      
      break if [200,301,304,308,307].include?(response&.status)
    end
    
    response&.body 
  end

  def get_cookie
    response = Hamster.connect_to(DATA_SOURCE_URL,headers: req_headers)
    reporting_request response
    @cookie = filter_cookies(response&.headers['set-cookie'])
  end
  
  def safe_connection(retries=10)
    begin
      yield if block_given?
    rescue *CONNECTION_ERROR_CLASSES => e
      begin
        retries -= 1
        raise 'Connection could not be established!' if retries.zero?
        logger.warn "Error: #{e.class}. Reconnect!"
        sleep 1 * (10-retries)
        PaidProxy.connection.reconnect!
        UserAgent.connection.reconnect!
      rescue *CONNECTION_ERROR_CLASSES => e
        retry
      end
      retry
    end
  end

  private

  def req_headers
    {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
      'Host': 'inmateinfo.indy.gov'
    }
  end

  def search_headers(cookies)
    {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Cookie': cookies,
      'Origin': 'http://inmateinfo.indy.gov',
      'Referer': 'http://inmateinfo.indy.gov/IML'
    }
  end

  def inmate_req_body(sys_id,img_sys_id)
    search_params = {
      'flow_action' => 'edit',
      'sysID' => sys_id,
      'imgSysID' => img_sys_id
    }

    req_body = search_params.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
  end

  def next_req_body(current_start)
    search_params = {
      'flow_action' => 'next',
      'currentStart' => current_start.to_s
    }

    req_body = search_params.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
  end

  def search_req_body(first_name='',last_name='')
    search_params = {
      'flow_action' => 'searchbyname',
      'quantity' => '10',
      'systemUser_identifiervalue' => '',
      'searchtype' => 'PIN',
      'systemUser_includereleasedinmate' => 'Y',
      'systemUser_includereleasedinmate2' => 'N',
      'systemUser_firstName' => first_name,
      'systemUser_lastName' => last_name,
      'systemUser_dateOfBirth' => '',
      'releasedA' => 'checkbox',
      'identifierbox' => 'PIN',
      'identifier' => ''
    }

    req_body = search_params.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    
  end

  def filter_cookies(cookie)
    cookie = cookie.gsub('path=/;','').gsub('Secure,','').gsub(' Secure','').gsub('HttpOnly;','').gsub('path=/','')
    cookie = cookie.gsub('expires=Tue, 12-Oct-1999 04:00:00 GMT;','').gsub(/; expires.+$/,'').squeeze(' ').strip
  end

  def reporting_request(response)
    logger.debug '=================================='
    logger.debug 'Response status: '.indent(1, "\t")
    status = response&.status
    logger.debug status.to_s
    logger.debug '=================================='
  end
end
