require_relative '../lib/irs_non_profit_parser'
require 'zip'

class IrsNonProfitScraper < Hamster::Scraper
  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @count        = 0
    @keeper       = keeper
    @debug        = commands[:debug]
    @proxies      = get_proxies
  end

  attr_reader :count

  def scrape_forms
    first_page(:forms)
    scrape_form('990s')
    scrape_form('pub_78')
    scrape_form('990_n')
    scrape_form('auto_rev_list')
  end

  def scrape_org
    rows      = 250
    link      = "https://apps.irs.gov/prod-east/teos/searchAll/ein?country=US&rows=250&page=0&sortBy=name&flow=asc"
    json_raw  = get_response(link).body
    json      = JSON.parse(json_raw)
    last_page = (json['count'] / rows) + 1
    last_page.times do |page|
      link = "https://apps.irs.gov/prod-east/teos/searchAll/ein?country=US&rows=#{rows}&page=#{page}&sortBy=name&flow=asc"
      sleep(rand(0.1..0.5))
      json = get_response(link).body
      peon.put(file: "orgs_#{page}.json", content: json, subfolder: "#{keeper.run_id}_orgs")
      @count += 1
    end
  end

  private

  def first_page(type=:org)
    link    = 'https://www.irs.gov/charities-non-profits/tax-exempt-organization-search-bulk-data-downloads'
    page    = get_response(link).body
    @parser = IrsNonProfitParser.new(html: page, type: type)
  end

  def scrape_orgs_csv
    csv_links = @parser.find_links
    csv_links.each do |link|
      name = link.split('/')[-1].split('.')[0]
      file = get_response(link).body
      peon.put(file: name+'.csv', content: file, subfolder: "#{keeper.run_id}_forms")
    end
  end

  def check_date(name)
    method_   = "parse_#{name}".to_sym
    forms     = @parser.send(method_)
    site_date = forms[:date]
    date_db   = keeper.last_data_source_update(name)
    data      = { site_date: site_date, link: forms[:link], name: name }
    #########
    #Add this variable because date not update on site
    #s = name == '990s'
    ########
    site_date > date_db ? data : nil
  end

  def scrape_form(name)
    info = check_date(name)
    return notify "#{name} has not been scraped, because the data is not updated" unless info

    name == '990s' ? scrape_form_990s(info) : scrape_other_form(info)
    notify "#{name} was scraped for #{info[:site_date]}"
  end

  def scrape_other_form(info)
    name   = "#{info[:name]}_#{info[:site_date].to_s.gsub('-', '_')}"
    stream = download_zip(info[:link])
    file   = unzip_file(stream)
    notify peon.put(file: name, content: file, subfolder: "#{keeper.run_id}_forms")
  end

  def scrape_form_990s(info)
    page       = get_response(info[:link]).body
    parser     = IrsNonProfitParser.new(html: page)
    date_db    = keeper.last_date
    years_urls = parser.parse_years(date_db)
    years_urls.each do |year_url|
      months_page = get_response(url: year_url).body
      parser      = IrsNonProfitParser.new(html: months_page)
      months_urls = parser.parse_months_urls
      months_urls.each do |path|
        next if date_db == date_db.end_of_month

        current_date = path.split('/')[-1].match(/\w{3,9}[-_]\d{4}/).to_s.to_date
        next unless current_date.end_of_month == date_db.end_of_month || current_date >= date_db

        csv  = get_response(url: path).body
        name = path.split('/')[-1].insert(0, info[:site_date].to_s.gsub('-', '_')+'_')
        peon.put(file: name, content: csv, subfolder: "#{keeper.run_id}_forms")
      end
    end
  end

  attr_reader :keeper

  def get_response(link, &block)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false, proxy: @proxies, &block)
  end

  def download_zip(link, try=50)
    response     = get_response(link)
    content_size = response.headers["content-length"].to_i
    body_size    = response.body.size
    raise "#{link} body_size less than the content_size" unless content_size == body_size

    response.body
  rescue => e
    try -= 1
    notify("Try number of #{try}", :red)
    notify(e.message, :red)
    try > 0 ? retry : Hamster.report(to: 'Eldar Eminov', message: "##{Hamster.project_number} | #{e}", use: :both)
    notify(e.full_message, nil)
  end

  def unzip_file(stream)
    result = nil
    Zip::File.open_buffer(stream) do |zip_file|
      zip_file.each { |entry| result = entry.get_input_stream.read }
    end
    result
  end

  def notify(message, color=:green)
    method_ = @debug ? :debug : :info
    message = color.nil? ? message : message.send(color)
    Hamster.logger.send(method_, message)
  end

  def get_proxies
    proxies = PaidProxy.all.pluck(:ip, :port, :login, :pwd, :is_socks5).shuffle
    PaidProxy.connection.close
    proxies.map { |p| "#{p.at(4) ? 'socks' : 'https'}://#{p.at(2)}:#{p.at(3)}@#{p.at(0)}:#{p.at(1)}" }
  end
end
