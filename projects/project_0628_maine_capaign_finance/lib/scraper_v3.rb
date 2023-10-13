# frozen_string_literal: true

HEADERS = {
  accept:                    'application/octet-stream',
  accept_language:           'en-US,en;q=0.9',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}

JSON_HEADERS = {
  accept:                    'application/json, text/plain, */*',
  # accept_encoding:           'gzip, deflate, br',
  accept_language:           'en-US,en;q=0.9',
  connection:                'keep-alive',
  content_type:              'application/json;charset=UTF-8'
}

require 'faraday_middleware'
require 'zip'

class ScraperV3 < Hamster::Scraper
  
  DOWNLOAD_API_URL = "https://mainecampaignfinance.com/api///DataDownload/CSVDownloadReport"
  CANDIDATE_API_URL = "https://mainecampaignfinance.com/api///Organization/SearchCandidates"
  COMMITTEE_API_URL = "https://mainecampaignfinance.com/api///Organization/SearchCommittees?electionYear=&party=&committeeType=&transactionType=&transactionAmount=&ballotQuestions=&stance=&pacType=&status=&BallotQuestionOnly=&JurisdictionType="
  TRANSACTION_JSON_API_URL = "https://mainecampaignfinance.com/api///Search/TransactionSearchInformation"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 49)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.include?('Access denied') || response.body.include?('you have been blocked') || response.body.include?('cloudflare.com')}
  end

  def download_all
    (2010..Date.today.year).each do |year|
      download_csv(year)
    end
  end

  def download_csv(year = Date.today.year)
    headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
      "content-type": "application/json;charset=UTF-8",
      "scheme": "https",
      "accept": "application/octet-stream",
      "accept-encoding": "gzip, deflate, br",
      "accept-language": "en-US,en;q=0.9",
      "origin": "https://mainecampaignfinance.com",
      "referer": "https://mainecampaignfinance.com/index.html",
      "Connection": "keep-alive"
    }

    dirname = storehouse+"store/#{year.to_s}/"
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    ["CON", "EXP"].each do |csv_type|
      filename = "#{csv_type}_#{year.to_s}.csv"
      connect_to(url: DOWNLOAD_API_URL, method: :get_file_with_post, filename: dirname + filename, headers: headers, req_body: download_parameters(year, csv_type).to_json)
    end
  end

  def download_xlsx_file(url, filename, sub_dir = '')
    dirname = storehouse+"store/#{sub_dir}"
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    flag = false
    until flag do 
      flag = true
      begin
        Hamster.logger.info "Connecting #{url}"
        connect_to(url: url, method: :get_file, filename: dirname + filename, headers: HEADERS)
        Hamster.logger.info "unzip #{dirname + filename}"
        unzip(dirname + filename)
      rescue 
        Hamster.logger.info "Rescue again"
        flag = false
      end
    end
  end

  # type: "CON", or "EXP"
  def get_transaction_json(year, type, page_num, page_size)
    response = connect_to(url: TRANSACTION_JSON_API_URL, proxy_filter: @proxy_filter, method: :post, headers: JSON_HEADERS, req_body: json_parameter(year, type, page_num, page_size).to_json)
    JSON.parse(response.body)
  end

  def get_candidates_json(year, page_num, page_size)
    page = connect_to(url: CANDIDATE_API_URL, proxy_filter: @proxy_filter, method: :post, headers: JSON_HEADERS, req_body: candidate_json_parameter(year, page_num, page_size).to_json)
    JSON.parse(page.body)
  end

  def get_committees_json(year, page_num, page_size)
    page = connect_to(url: COMMITTEE_API_URL, proxy_filter: @proxy_filter, method: :post, headers: JSON_HEADERS, req_body: committee_json_parameter(year, page_num, page_size).to_json)
    JSON.parse(page.body)
  end

  # csv_type: "CON", "EXP"
  def get_csv(csv_type, year)
    File.open("#{storehouse}store/#{year}/#{csv_type}_#{year}.csv", "r:ISO-8859-1")
  end

  def clear_files(year)
    # Dir.glob("#{storehouse}store/#{year.to_s}/*").each { |file| File.delete(file) }
    FileUtils.rm_r Dir.glob("#{storehouse}store/#{year.to_s}/")
  end

  # Params  year: Number
  # Params  type: String, One of "EXP" or "CON"
  def download_parameters(year, type = "EXP")
    { "year" => year, "transactionType" => type }
  end

  def committee_json_parameter(year, page_num = 1, page_size = 100)
    {
      "electionYear" => "#{year}",
      "party" => nil,
      "committeeType" => nil,
      "transactionType" => nil,
      "transactionAmount" => nil,
      "ballotQuestions" => nil,
      "stance" => nil,
      "pacType" => nil,
      "status" => nil,
      "BallotQuestionOnly" => nil,
      "JurisdictionType" => nil,
      "pageNumber"=> "#{page_num}",
      "pageSize"=> page_size
    }
  end

  def candidate_json_parameter(year, page_num = 1, page_size = 100)
    {
      "ElectionYear" => year,
      "Party" => nil,
      "OfficeSought" => nil,
      "JurisdictionType" => nil,
      "Jurisdiction" => nil,
      "FinanceType" => nil,
      "TransactionType" => nil,
      "TransactionAmount" => nil,
      "DistrictId" => nil,
      "pageNumber" => "#{page_num}",
      "pageSize" => page_size,
      "electionId" => nil
    }
  end

  def json_parameter(year, type = 'CON', page_num = 1, page_size = 100)
    {
      "TransactionType"=> type,
      "CommitteeType"=> nil,
      "ElectionYear"=> year,
      "CommitteeName"=> nil,
      "TransactionCategoryCode"=> "",
      "AmountType"=> nil,
      "ContributorPayeeName"=> nil,
      "TransactionBeginDate"=> nil,
      "TransactionEndDate"=> nil,
      "TransactionAmount"=> nil,
      "ValidationRequired"=> 0,
      "TransactionUnderAmount"=> nil,
      "pageNumber"=> "#{page_num}",
      "pageSize"=> page_size,
      "sortDir"=> "",
      "sortedBy"=> "",
      "ContributorType"=> nil,
      "TransactionPurpose"=> nil,
      "FinancingType"=> nil,
      "JurisdictionType"=> nil
    }
  end

  def search_parameters(search_parameters = {}, page_num = 1, page_size = 100)
    {
      'TransactionType' => 'CON',
      'CommitteeType' => '01,02,03,09',
      'ElectionYear' => '2020,2019,2018,2017,2016,2015,2014,2013,2012,2011,2010,2009,2008',
      'TransactionCategoryCode' => 'All',
      'ContributorType' => 'IND',
      'ValidationRequired' => 0,
      'pageNumber' => page_num.to_s,
      'pageSize' => page_size.to_s,
      'sortDir' => 'asc',
      'sortedBy' => 'Name'
    }.merge(search_parameters).to_json
  end

  def connect_to(*arguments, &block)
    return nil if arguments.nil? || arguments.empty?
    
    given_arguments = arguments.dup
    url             = arguments.first.is_a?(String) ? arguments.shift : arguments.first[:url]
    
    return nil if url.nil?
    
    arguments    = arguments.first.dup
    condition    = arguments.is_a?(Hash)
    headers      = (condition ? arguments[:headers].dup : nil) || {}
    req_body     = condition ? arguments[:req_body].dup : nil
    proxy        = condition ? arguments[:proxy].dup : nil
    cookies      = condition ? arguments[:cookies].dup : nil
    proxy_filter = condition ? arguments[:proxy_filter].dup : nil
    iteration    = (condition ? arguments[:iteration].dup : nil) || 0
    open_timeout = (condition ? arguments[:open_timeout].dup : nil) || 5
    method       = (condition ? arguments[:method].dup : nil) || :get
    timeout      = (condition ? arguments[:timeout].dup : nil) || 60
    ssl_verify   = (condition ? arguments[:ssl_verify].dup : true)
    filename     = (condition ? arguments[:filename].dup : nil)
    matched_url  = url ? url.match(%r{^(https?://[-a-z0-9._]+)(/.+)?}i) : nil
    url_domain   = matched_url ? matched_url[1] : ''
    url_path     = matched_url ? matched_url[2] : '/'
    
    if iteration == 10
      log "\nLoop depth more than 10.", :red
      exit 0
    end
    
    current_proxy = nil
    proxy         = Camouflage.new(proxy)
    retries       = 0
    response      = nil
    headers       = headers.merge(user_agent: FakeAgent.new.any) unless headers.include?(:user_agent)
    headers.merge!(cookies) if cookies

    begin
      current_proxy = proxy.swap

      if proxy_filter
        while proxy_filter.filter(current_proxy).nil? && proxy.count > proxy_filter.count
          logger.info "Bad proxy filtered: ".yellow + current_proxy.to_s.red if @debug
          current_proxy = proxy.swap
        end
      end
      
      faraday_params = {
        url:     url_domain,
        ssl:     { verify: ssl_verify },
        proxy:   current_proxy,
        request: {
          open_timeout: open_timeout,
          timeout:      timeout
        }
      }
      connection     =
        Faraday.new(faraday_params) do |c|
          c.request :multipart
          c.headers = headers
          c.adapter :net_http
          c.response :logger
        end
      response       =
        case method
        when :get
          connection.get(url_path)
        when :post
          connection.post(url_path, req_body)
        when :get_file
          file = open(filename, "wb")
          begin
            connection.get(url_path) do |req|
              req.options.on_data = Proc.new do |chunk, _|
                file.write chunk
              end
            end
          ensure
            file.close
          end
        when :get_file_with_post
          begin
            file = open(filename, "wb")  
            connection.post(url_path, req_body) do |req|
              req.options.on_data = Proc.new do |chunk, _|
                file.write chunk
              end
            end
          ensure
            file.close
          end
        else
          nil
        end
      # if response.body.include?('cloudflare.com')
      #   raise "cloudflare blocked"
      # end
    rescue Interrupt, SystemExit
      log "\nInterrupted by user.", :red
      exit 0
    
    rescue Exception => e
      retries += 1
      sleep(rand(15))
      
      if retries <= proxy.count
        logger.info e.message
        logger.info e.full_message if @debug
        logger.info "Retry connection ##{retries}" if @debug
        if proxy_filter && current_proxy
          proxy_filter.ban(current_proxy)
          logger.info "Proxy #{current_proxy} was banned.".red if @debug
        end
        retry
      else
        logger.info e.message
        response = nil
      end
    
    else
      check_response = block_given? ? block.call(response) : (response.headers[:content_type].match?(%r{text|html|json|pdf|application}) || !response.headers[:server].nil?)
      
      if proxy_filter&.ban_reason?(response)
        proxy_filter&.ban(current_proxy)
        logger.info "Proxy #{current_proxy} was banned.".red if @debug
      end
      
      unless check_response
        countdown(35 - rand(30), label: 'Waiting before reconnecting...')
        
        if given_arguments.last.is_a?(Hash)
          given_arguments.last.merge!(iteration: iteration + 1)
        else
          given_arguments << { iteration: iteration + 1 }
        end
        
        connect_to(*given_arguments, &block)
      end
      
      response
    ensure
      
      response
    end
  end

  def unzip(file_path)
    trash_path = storehouse + 'trash/'    
    Zip::File.open(file_path) do |zip_file|
      zip_file.each do |f|
        if (!f.name.downcase.include?('fileheader') && !f.name.include?('.xlsx'))
          zip_file.extract(f, file_path) unless File.exist?(file_path)
        end
      end
    end
  end
end
