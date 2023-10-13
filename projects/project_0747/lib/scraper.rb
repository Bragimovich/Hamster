# frozen_string_literal: true

class Scraper < Hamster::Scraper
  attr_writer :page, :fix_page
  def initialize
    super
    @agent = Mechanize.new
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @agent.user_agent_alias = 'Mac Safari'
    @proxies = PaidProxy.where(is_socks5: 1).where(locked_to_scrape07: 0).to_a
    swap_proxy
  end

  def swap_proxy
    @proxy = @proxies.sample
    proxy_addr = @proxy[:ip]
    proxy_port = @proxy[:port]
    proxy_user = @proxy[:login]
    proxy_passwd = @proxy[:pwd]
    socks_proxy = "socks://#{proxy_user}:#{proxy_passwd}@#{proxy_addr}:#{proxy_port}"
    @agent.agent.set_proxy(socks_proxy)
  end

  def main_page
    retries = 0
    begin
      content = @agent.get("https://apps.ark.org/inmate_info/index.php")
      @logger.info(content.code)
      content.body
    rescue => e
      @logger.debug(e.class)
      @logger.debug(e.message)
      if e.class == SOCKSError
        retries += 1
        retry if retries < 5
      end
    end
  end

  def get_arrest_page(link)
    content = @agent.get(link)
    @logger.info(content.code)
    content.body
  end

  def search_page(token, county)
    params = {
    'token' => token,
    'COUNTY' => county,
    'FAC' => '0',
    'sex' => 'b',
    'CRIME' => '0',
    'agetype' => '1',
    'RACE' => '0',
    'disclaimer' => '1',
    'B1' => 'Search'
  }
    content = @agent.post("https://apps.ark.org/inmate_info/search.php", params)
    @logger.info(content.code)
    content.body
  end

  def view_info(url)
    retries = 0
    url = fix_page(url) if @fix_page
    begin
      content = @agent.get(url)
      @logger.info(content.code)
      content.body
    rescue => e
      @logger.debug(e.class)
      @logger.debug(e.message)
      if e.class == SOCKSError
        retries += 1
        retry if retries < 5
      end
    end
  end

  def fix_page(url)
    link = []
    url.split("&").each do |part|
      part = part.replace("RUN=#{@page.to_i - 1}") if part.include?("RUN")
      link << part
    end
    @fix_page = false
    link.join("&")
  end

  def store_to_aws(link)
    @aws_s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)
    cobble = Dasher.new(:using=>:cobble)
    body = cobble.get(link)
    key = Digest::MD5.new.hexdigest(link)
    mugshot_link = @aws_s3.put_file(body, "crimes_mugshots/AR/#{key}.jpg")
  end
end 
