require 'nokogiri'

class USPatentsScraper < Hamster::Scraper
  HEADERS = {
    accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    accept_encoding:           'gzip, deflate',
    accept_language:           'en-US,en;q=0.9',
    cache_control:             'max-age=0',
    sec_fetch_dest:            'document',
    sec_fetch_mode:            'navigate',
    sec_fetch_site:            'none',
    sec_fetch_user:            '?1',
    upgrade_insecure_requests: '1',
    cookie:                    'TS01a6c8e4=01874167c71b3b21ae55710dff6468802ca07fe731fdbefef2699197564cf9a9cf1413b3a9bd6e3dc8b72b5955db59ab938e527776'

    # accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    # accept_encoding:           'gzip, deflate',
    # accept_language:           'en-US,en;q=0.9',
    # cache_control:             'max-age=0',
    # sec_fetch_dest:            'document',
    # sec_fetch_mode:            'navigate',
    # sec_fetch_site:            'none',
    # sec_fetch_user:            '?1',
    # upgrade_insecure_requests: '1',
  }.freeze

  def initialize
    super
    # @user_agent_list = [
    #   'Mozilla/5.0 (Windows NT 6.3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.66 Safari/537.36',
    #   'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.60 YaBrowser/20.12.0.963 Yowser/2.5 Safari/537.36',
    #   'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 YaBrowser/20.9.3.136 Yowser/2.5 Safari/537.36',
    #   'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 (Chromium GOST) Safari/537.36',
    #   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36 Edg/87.0.664.66',
    #   'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.104 Safari/537.36 Core/1.53.2372.400 QQBrowser/9.5.11096.400',
    # ]
    # @proxy_list = PaidProxy.all

    puts storehouse.to_s.red
    puts peon

    FileUtils.mkdir_p storehouse + 'log/'
    @logger = Logger.new(storehouse + 'log/' + "scraping_#{Date.today.to_s}.log", 'monthly', 50 * 1024 * 1024)
    @not_parsed_file_path = storehouse + 'store/' + 'not_parsed_list.txt'
  end

  def scrape(year, month='$', day='$', continue=false, list=[], where_proxy)
    filter  = ProxyFilter.new(duration: 3.hours, touches: 1_000)
    mode = list.nil? ? '' : :list

    # filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }

    peon.throw_trash(30)

    @logger.info "Start scraping for YEAR: #{year}#{" MONTH: #{month}" if month != '$'}#{" DAY: #{day}" if day != '$'}."
    max_count = nil
    if mode == :list
      counter = list.shift
      stop = false
    else
      if continue
        counter = get_next_id
      else
        counter = 1
      end
    end

    proxy_list = []
    PaidProxy.where(where_proxy).to_a.each {|p| proxy_list << "#{p.is_socks5 ? 'socks' : 'https'}://#{p.login}:#{p.pwd}@#{p.ip}:#{p.port}"}
    # PaidProxy.where("id not in (1,2,29)").to_a.each {|p| proxy_list << "#{p.is_socks5 ? 'socks' : 'https'}://#{p.login}:#{p.pwd}@#{p.ip}:#{p.port}"}
    proxy_list = proxy_list.shuffle

    puts proxy_list

    fa = FakeAgent.new
    user_agent = fa.any

    wrong_body_count = 0
    loop do
      puts "SCRAPING NOW ID: ".green + "#{counter} OF #{max_count}".cyan
      url = "https://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO2&Sect2=HITOFF&u=%2Fnetahtml%2FPTO%2Fsearch-adv.htm&r=#{counter}&f=G&l=50&d=PTXT&p=1&S1=#{year}#{month}#{day}.PD.&OS=ISD/#{month}/#{day}/#{year}&RS=ISD/#{year}#{month}#{day}"
      url_path = "/netacgi/nph-Parser?Sect1=PTO2&Sect2=HITOFF&u=%2Fnetahtml%2FPTO%2Fsearch-adv.htm&r=#{counter}&f=G&l=50&d=PTXT&p=1&S1=#{year}#{month}#{day}.PD.&OS=ISD/#{month}/#{day}/#{year}&RS=ISD/#{year}#{month}#{day}"
      puts url.yellow
      proxy = proxy_list.shift
      # full_page = Nokogiri::HTML.parse(connect_to(url: url, headers: HEADERS, proxy: @proxy, proxy_filter: filter).body)
      # response = connect_to(url: url, headers: HEADERS, proxy: @proxy)

        # conn = Faraday.new('https://patft.uspto.gov', ssl: {verify: true}, headers: HEADERS.merge({"User-Agent" => @user_agent_list.any}), proxy: proxy)


      # user_agent = @user_agent_list.sample
      loop do
        user_agent = fa.any
        break unless user_agent.match?(/google|parser|headless|preview|Facebot|Twitterbot/i)
      end
      puts user_agent.cyan
      response =
        Faraday.new(url: url, ssl: {verify: true}, proxy: proxy) do |c|
          c.headers = HEADERS.merge({"User-Agent" => user_agent})
          c.adapter :net_http
          puts c.headers
        end.get

      # response = conn.get(url_path)

      # conn.close
      if response.status == 200 && response.body.size.positive?
        puts 'STATUS 200. PROCEEDING'.green
      else
        puts "STATUS #{response.status}. ERROR".red
        exit 1
      end
      # content = Nokogiri::HTML.parse(connect_to(url: url, headers: HEADERS, proxy: @proxy).body).css('body')
      content = Nokogiri::HTML.parse(response.body).css('body')
      return if content.text.include?('No patents have matched your query')

      if max_count.nil?
        puts "1 >> #{content.nil?}"
        puts "2 >> #{content.css('table')[1].nil?}"
        max_count = content.css('table')[1].css('strong')[1].text.strip.to_i
        break if max_count.zero?
      end
      peon.put(file: "#{year}#{"-#{month}" unless month == '$'}#{"-#{day}" unless day == '$'}_#{counter.to_s.rjust(8, '0')}", content: content.to_html) #, subfolder: found_dir)
      puts storehouse + 'store/' + "#{year}#{"-#{month}" unless month == '$'}#{"-#{day}" unless day == '$'}_#{counter.to_s.rjust(8, '0')}" + '.gz'
      puts File.size(storehouse + 'store/' + "#{year}#{"-#{month}" unless month == '$'}#{"-#{day}" unless day == '$'}_#{counter.to_s.rjust(8, '0')}" + '.gz').to_s.cyan
      puts wrong_body_count
      puts proxy_list.size
      if File.size(storehouse + 'store/' + "#{year}#{"-#{month}" unless month == '$'}#{"-#{day}" unless day == '$'}_#{counter.to_s.rjust(8, '0')}" + '.gz') < 800
        wrong_body_count += 1
        if wrong_body_count > proxy_list.size
          puts "Can't access #{counter} page..."
          break
        else
          proxy_list << proxy
          next
        end
      end
      wrong_body_count = 0

      if mode == :list
        if list.empty?
          stop = true
        else
          counter = list.shift
        end
      else
        counter += 1
      end
      break if counter > max_count || max_count.zero? || (mode == :list && stop )
      proxy_list << proxy
      # if counter % (proxy_list.count + 1) == 0
      #   sleep(60 * rand(5.5..7.5))
      # else
        sleep(rand(1.1..3.5))
      # end
    end
    @logger.info "Scraping finished."

  end

  private

  def get_next_id
    peon.give_list.sort.last.split('_').last.split('.').first.to_i + 1
  end
end
