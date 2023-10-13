# frozen_string_literal: true
require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  DATA_SOURCE_URL = 'https://www.huduser.gov/portal/datasets/assthsg.html#2009-2022'

  def initialize
    super
    @host = "https://www.huduser.gov"
  end

  def download_main_page
    @cookie ||= get_cookie
    response = []
    
    10.times do
      headers = req_headers(@cookie)
      response = Hamster.connect_to(DATA_SOURCE_URL, headers: headers)
      reporting_request response
      
      break if [200,301,304,308,307].include?(response&.status)
    end

    response&.body
  end

  def download_file(link)
    @cookie ||= get_cookie
    response = nil
    
    10.times do
      headers = file_headers(@cookie)
      response = Hamster.connect_to(link, headers: headers)
      reporting_request response
      
      break if [200,301,304,308,307].include?(response&.status)
    end
    
    if response&.headers["content-type"]&.match?(/sheet/)
      logger.debug 'successfully downloaded file'
      response&.body 
    end
  end

  def get_cookie
    response = Hamster.connect_to(DATA_SOURCE_URL,headers: req_headers(nil))
    reporting_request response
    @cookie = filter_cookies(response&.headers['set-cookie'])
  end

  def download_and_save_file(link)
    file_url = absolute_url(link)
    file_name = Digest::MD5.hexdigest(absolute_url(link))
    data = download_file(file_url)
    save_file(data, file_name)
    save_link(file_url, file_name)
  end

  def absolute_url(link)
    link = "#{@host}#{link}" unless link.start_with?('http')

    link
  end

  def files_path
    "#{storehouse}store/files"
  end

  def links_path
    "#{storehouse}store/links"
  end

  def cleanup
    logger.debug("files cleanup")
    FileUtils.rm Dir[files_path+"/*"]
    FileUtils.rm Dir[links_path+"/*"]
  end 

  private

  def req_headers(cookie)
    headers = {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9'
    }
    headers.merge({"Cookie": cookie}) unless cookie.nil?
  end

  def file_headers(cookies)    
    req_headers(cookies).merge({"referer": "https://www.huduser.gov/portal/datasets/assthsg.html"})
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

  def save_file(file, file_name)
    FileUtils.mkdir_p files_path
    file_path = "#{files_path}/#{file_name}.xlsx"
    File.open(file_path, "wb") do |f|
      f.write(file)
    end
  end

  def save_link(file_url, file_name)
    FileUtils.mkdir_p links_path
    file_path = "#{links_path}/#{file_name}.link"
    File.open(file_path, "wb") do |f|
      f.write(file_url)
    end
  end
end
