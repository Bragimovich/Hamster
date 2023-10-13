# frozen_string_literal: true

class Scraper < Hamster::Scraper
  attr_accessor :cookies

  ORIGIN         = "https://courts.ms.gov"
  MAIN_URL       = "https://courts.ms.gov/index.php"
  POST_URL       = "https://courts.ms.gov/appellatecourts/docket/showMore.php"
  INNER_PAGE_URL = "https://courts.ms.gov/appellatecourts/docket/build_docket.php"
  OPINION_URL    = "https://courts.ms.gov/appellatecourts/docket/get_hd_file.php"

  def initialize(*_)
    safe_connection { super }
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @cookies = nil
  end

  def create_post(params = {})
    raise "Terms was not set" unless params[:terms]
    @cookies ||= connect_to_set_cookie

    page = params[:page] || 1
    row_count = params[:row_count] || 1
    form_data = "search_terms=#{params[:terms]}&page=#{page}&rowcount=#{row_count}"
    
    connect_to(POST_URL,
              proxy_filter: @filter,
              method: :post,
              req_body: form_data,
              headers: set_headers
              )&.body 
  end

  def get_inner_page(id:, type:)
    headers = set_headers
    headers["Refer"] += "?cn=#{id}"

    data_links = { 
      'info' => "docket_type=lcinfo&case_num=#{id}", 
      'party' => "docket_type=apinfo&case_num=#{id}&listby=att", 
      'docket' => "docket_type=docket&sortdir=desc&case_num=#{id}&limit=true", 
      'opinion' => "docket_type=opinion&case_num=#{id}" 
    } 
      
    form_data = data_links[type]
    
    connect_to(INNER_PAGE_URL,
              proxy_filter: @filter,
              method: :post,
              req_body: form_data,
              headers: headers
              )&.body 
  end

  def download_pdf(url, tries: 100)
    Hamster.logger.info("Processing URL -> #{url}")
    response = safe_connection { Hamster.connect_to(url: url, proxy_filter: @proxy_filter, headers: {"Cookie" => @cookies}, ssl_verify:{:verify => true}) }
    reporting_request(response)
    raise if response.nil? || response.status != 200 || response.body.include?('Please try your request again soon')
    response.body
  rescue => e
    tries -= 1
    if tries < 1
      return nil
    else
      sleep(rand(10))
      Hamster.logger.error("PDF not downloaded....Retry....")
      retry
    end
  end

  def get_opinion_info(court_type, date)
    part_url = court_type.downcase.chomp('t')
    headers = set_headers
    headers["Refer"] = "https://courts.ms.gov/appellatecourts/#{part_url}/#{part_url}decisions.php?date=#{date}"
    form_data = "court=#{court_type}&date=#{date}"
    response = connect_to(OPINION_URL,
                          proxy_filter: @filter,
                          ssl_verify: false,
                          method: :post,
                          req_body: form_data,
                          headers: headers
                          )

    response.status == 200 ? response.body : nil
  end

  def connect_to(*arguments, &block)
    response = nil
    safe_connection { 
      10.times do
        response = super(*arguments, &block)
        reporting_request(response)
        break if response&.status && [200, 304, 302].include?(response.status)
      end
    }
    response
  end

  private

  def connect_to_set_cookie
    connect_to(MAIN_URL)&.headers['set-cookie']
  end

  def reporting_request(response)
    Hamster.logger.debug '=================================='
    Hamster.logger.info 'Response status: '.indent(1, "\t")
    status = response&.status
    Hamster.logger.info status.to_s
    Hamster.logger.debug '=================================='
  end  

  def set_headers
    {
      "Accept" => "*/*",
      "Accept-Language" => "ru,en;q=0.9",
      "Connection" => "keep-alive",
      "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
      "Cookie" => @cookies,
      "Host" => "courts.ms.gov",
      "Origin" => "https://courts.ms.gov",
      "Refer" => "https://courts.ms.gov/index.php",
      "X-Requested-With" => "XMLHttpRequest",
      "Sec-Fetch-Site" => "same-origin",
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 YaBrowser/22.11.5.715 Yowser/2.5 Safari/537.36"
    }
  end

  def safe_connection(retries=10) 
    begin
      yield if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        Hamster.logger.error(e.class)
        sleep 100
        PaidProxy.connection.reconnect!
        UserAgent.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end

      retry
    end
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
