# frozen_string_literal: true
require_relative '../lib/download_pdf'
require_relative '../lib/divide_activities'
require_relative '../lib/transfers_courts'
require_relative '../lib/pdf_investigate'
require_relative '../lib/pacer_files'


def scrape(options)
  limit = 1000
  limit = @arguments[:limit] if @arguments[:limit]
  if @arguments[:trying]
    
    cobble = Hamster::Scraper::Dasher.new(:using=>:cobble, :redirect=>true)
    #q = 'https://www.licensedlawyer.org/cv/cgi-bin/memberdll.dll/CustomList?WHP=lawyers_header.htm&WBP=lawyers_list.htm&SQLNAME=GETDIRSEARCH&SRCHOPT=I%7CSTATECD%7CCO%7C%3D%5EI%7CCHAPTERID%7CCO-BAR%7C%3D&SORTOPT=LASTNAME%2C+FIRSTNAME&GETCOUNT=0&GETSIM=0&RANGE=11/10&WEM=search_error.htm'
    #q = "https://www.licensedlawyer.org/cv/cgi-bin/memberdll.dll/info?WRP=lawyerProfileT.htm&CUSTOMERCD=2009984"
    q = "https://www.licensedlawyer.org/cv/cgi-bin/utilities.dll/CustomList?WMT=none&WHP=none&WBP=../tags.htm&QNAME=NGLAWYERTAX&CUSTCD=2009984&WNR=none"
    ans = cobble.get(q)
    p ans
  end

  if @arguments[:aws_1]
    q = AwsS3.new(bucket_key = :hamster, account=:hamster)
    p q
    p q.put_file('ffffffAAAAAAA', 'DELETE_11111', metadata={})

  end

  court_id=nil
  if @arguments[:court_id]
    court_id = @arguments[:court_id]
  end

  if @arguments[:pdf_ocr]

    if @arguments[:stream]
      stream = @arguments[:stream]
      streams = @arguments[:streams]
      pdf_from_aws(court_id, stream, streams)
    else
      pdf_from_aws(court_id)
    end
  end

  if @arguments[:delete_aws]
    @s3 = AwsS3.new(bucket_key = :loki, account=:loki)
    key_start = "congressional_legislation_"
    @s3.delete_files(key_start)
  end

  if @arguments[:using]
    using= @arguments[:using]
  end

  if @arguments[:robohamster]
    # q =  Hamster::ConfigCompiler.new()
    # q.to_hash('./config/site_config.yml')
    scr = Hamster::Scraper.new()
    config = 'site_config_ohio'
    #config = 'site_config_dept_of_transport'
    config = 'site_config_fcc'
    q =  scr.robohamster("./config/#{config}.yml")

  end

  if @arguments[:pdf_analysis]
    if @arguments[:limit]
      limit = @arguments[:limit]
    else
      limit = 5000
    end

    if @arguments[:court_id]
      court_id = @arguments[:court_id]
    else
      court_id = 2
    end

    get_pdf(limit, court_id)
  end

  if @arguments[:pdf_analysis_pacer]
    if @arguments[:project]
      project = @arguments[:project]
    else
      project = 54
    end

    pcr = PacerFiles.new(project)
    #pcr.open(project)
  end


  if @arguments[:check_md5]
    cols = %i[court_id case_id party_name party_type]
    md5 = MD5Hash.new(:columns=>cols)
    data = { court_id: 999, case_id: 12, party_name: 'Maxim', party_type: 'person' }
    p md5.generate(data)


  end

  if @arguments[:mech]
    cobble = Hamster::Scraper::Dasher.new(:using=>:cobble, :redirect=>true, :pc=>1)
    q=  'https://appellatecases.courtinfo.ca.gov/search/case/mainCaseScreen.cfm?dist=1&doc_id=45361&doc_no=A093470&search=party&start=26&request_token=auth'
    q = 'https://appellatecases.courtinfo.ca.gov/search/case/mainCaseScreen.cfm?doc_id=2016090&request_token=NiIwLSEmPkw6WyBVSSJNVElIUEQ6UVxfICNOXzpRICAgCg%3D%3D&start=1&doc_no=A135609&dist=1&search=party&auth=yes'
    cobble.get('https://appellatecases.courtinfo.ca.gov/search/searchResults.cfm?dist=1&search=party&query_partyLastNameOrOrg=AA&start=26')
    q = 'https://appellatecases.courtinfo.ca.gov/search/case/mainCaseScreen.cfm?dist=1&doc_id=39280&doc_no=A087387&search=party&start=26&request_token=auth'

    p cobble.get(q)
    p cobble.headers
  end

  if @arguments[:check_proxy]
    urls = ['https://www.google.com', 'https://www.amazon.com', 'https://iapps.courts.state.ny.us/nyscef/CaseSearch?TAB=courtDateRange']
    filename = '/Users/Magusch/HarvestStorehouse/project_0994/proxies.txt'
    #File.open(filename, 'w') { |file| file.write("proxies       |#{urls.join('         |')}\n") }
    File.open(filename, 'w') { |file| file.write("proxies                        |URL                     | ANSWER\n") }
    counter = 0
    used_proxies = []


    loop do
      cobble = Hamster::Scraper::Dasher.new(:using=>:crowbar, :redirect=>true, :pc=>1)
      cobble.connect
      #next if cobble.current_proxy.in?(used_proxies)
      #File.open(filename, 'a') { |file| file.write("#{cobble.current_proxy} |") }
      urls.each_with_index do |url, i|
        p cobble.current_proxy
        q = nil
        begin
          q = cobble.get(url)
        rescue => e
          #File.open(filename, 'a') { |file| file.write("#{e}") }
          File.open(filename, 'a') { |file| file.write("#{cobble.current_proxy}                |#{url}                     | #{e}\n") }
        else
          if q.nil?
            File.open(filename, 'a') { |file| file.write("#{cobble.current_proxy}                |#{url}                     | nil\n") }
          else
            File.open(filename, 'a') { |file| file.write("#{cobble.current_proxy}                |#{url}                     | good\n") }
          end

        end
      end
      #File.open(filename, 'a') { |file| file.write("\n") }
      #used_proxies.push(cobble.current_proxy)
      break if counter==100
      counter+=1

    end




  end


  if @arguments[:lawyer]
    lawyers_table
  elsif @arguments[:info]
    transfer_info
  elsif @arguments[:party]
    transfer_party
  end
  if @arguments[:check_coble]
    using = 'hammer' if using.nil?
    br = Hamster::Scraper::Dasher.new(using: using.to_sym)
    br.get('https://www.google.com/')
    p br.cookies
    p br.headers
    #p br
    # q = br.get('https://myip2.ru')
    # p q
  elsif @arguments[:myip]
    url = "https://myip2.ru"
    using = 'hammer' if using.nil?
    dash = Hamster::Scraper::Dasher.new(using: using.to_sym, ssl_verify:false, options:{'--ignore-urlfetcher-cert-requests' => true})
    body = dash.get(url)
    ip = parse_myip(body) if body
    p using
    p ip
    p "Proxy: #{dash.current_proxy}"

  elsif @arguments[:cobble]
    br = Hamster::Scraper::Dasher.new(using: :hammer)

  elsif @arguments[:get_file]
    url = 'https://iapps.courts.state.ny.us/nyscef/ViewDocument?docIndex=pXNmtVVqseVSS0mWn3k2fQ=='
    br = Hamster::Scraper::Dasher.new(using: :crowbar, ssl_verify:false)
    br.get_file(url, filename: '1122')
    #br.get_file(url, filename: '1122')

  elsif @arguments[:check_ham]
    q=0

    br = Hamster::Scraper::Dasher::Hammer.new()
    q = br.connect
    p q
    q = br.get('https://myip2.ru')
    p q
    br.connect
    #   q = br.get('https://myip2.ru')
    #   p q.response
    #   q = br.get('https://www.rubydoc.info/gems/mechanize/Mechanize/Page#response_header_charset-class_method')
    #   p q.response_code
    #   p br.response_code
    # rescue => e
    #   p e
    #   q+=1
    #   retry if q<10

    #p q.body
  elsif @arguments[:check_dasher_ham]
    q = Hamster::Scraper::Dasher.new(using: :hammer, pc:1, headless:true)
    p 'open browser'
    sleep(30)
    p 'go'
    page = q.get("https://api.ipify.org?format=json")
    p q.current_proxy
    p page

    page = q.get("https://api.ipify.org?format=json")
    p q.current_proxy
    p page
    q.close

    p 'close first'
    sleep(30)
    p 'go'
    puts
    page = q.get("https://api.ipify.org?format=json")
    p q.current_proxy
    p page
    puts
    sleep(5)

    page = q.get("https://api.ipify.org?format=json")
    p q.current_proxy
    p page
    puts
    p 'open browser'
    sleep(60)
    p 'close'
    q.close
    #q.connect
    #browser = q.connection

    #browser = Ferrum::Browser.new()
    p 'finish'

    # context = browser.contexts.create
    # #context
    # sleep(2)
    # page = context.create_page
    # page.go_to("https://www.google.com/search?q=Ruby+headless+driver+for+Capybara")
    # page = context.create_page
    # #p page.client
    # p context.targets.each_value { |q| p q  }
    # context.dispose
    # p context.targets['entries']


    #browser.network.authorize(user: 'noihtpkm', password: 'h4kbu0kn5ruo', type: :proxy) { |r| r.continue }
    sleep 5
    # page2 = browser.create_page
    # page2.go_to("https://www.google.com/")
    # sleep(10)
    # page.close
    # sleep 5
    #sleep 10
    # t1 = Thread.new(browser) do |b|
    #   context = b.contexts.create
    #   page = context.create_page
    #   page.go_to("https://www.google.com/search?q=Ruby+headless+driver+for+Capybara")
    #   #page.screenshot(path: "t1.png")
    #   sleep 20
    #   context.dispose
    #   p 'disposed'
    # end

    p 'quit'

  elsif @arguments[:check_dasher_ham2]
    q = Hamster::Scraper::Dasher.new(using: :hammer, pc:1, headless:false, proxy_server:1)
    q.connect
    browser = q.connection
    p 'working'

    browser.proxy_server.rotate(host: "192.241.125.114", port: 8158, user: "noihtpkm", password: "h4kbu0kn5ruo")
    browser.create_page(new_context: true) do |page|
      page.go_to("https://api.ipify.org?format=json")
      p page.body # => "x.x.x.x"
      sleep 10
    end
    sleep 3
    browser.proxy_server.rotate(host: "45.57.237.158", port: 8233, user: "noihtpkm", password: "h4kbu0kn5ruo")
    browser.create_page(new_context: true) do |page|
      page.go_to("https://api.ipify.org?format=json")
      p page.body # => "y.y.y.y"
      sleep 5
    end
    p 'end'
  elsif @arguments[:dasher_111]
    hammer = Hamster::Scraper::Dasher.new(using: :hammer)
    cobble = Hamster::Scraper::Dasher.new(using: :cobble)
    @peon =  Hamster::Scraper::Peon.new("../checker/")
    list = ["https://courtconnect.courts.delaware.gov/cc/cconnect/ck_public_qry_doct.cp_dktrpt_docket_report?backto=P&case_id=N21M-04-132&begin_date=&end_date=", "https://courtconnect.courts.delaware.gov/cc/cconnect/ck_public_qry_doct.cp_dktrpt_docket_report?backto=P&case_id=N22M-05-031&begin_date=&end_date=", "https://courtconnect.courts.delaware.gov/cc/cconnect/ck_public_qry_doct.cp_dktrpt_docket_report?backto=P&case_id=JP16-09-004935&begin_date=&end_date=", "https://caseinfo.arcourts.gov/cconnect/PROD/public/ck_public_qry_doct.cp_dktrpt_docket_report?backto=C&case_id=D-22-31&citation_no=&begin_date=&end_date="]

    list.each_with_index do |link, i|
      page = hammer.get(link)
      @peon.put(content: page, file: "#{i}_browser.html")
      page = cobble.get(link)
      @peon.put(content: page, file: "#{i}_faradey.html")
    end

  elsif @arguments[:check_dasher]
    br = Hamster::Scraper::Dasher.new(using: :cobble, use_proxy:2)
    br.get('https://widget.afisha.yandex.ru/w/sessions/MjI3Njl8MjQyNTgwfDMyMTUwNXwxNjMzNTMyNDAwMDAw?clientKey=4d9a69ed-775c-448a-9eae-fa18a49a6d19&utm_source=beat&utm_medium=fest_link&utm_campaign=1639964967.1631554120')
    cobble_cook=br.cookies
    p '________'
    br = Hamster::Scraper::Dasher.new(using: :crowbar, use_proxy:2)
    br.get('https://widget.afisha.yandex.ru/w/sessions/MjI3Njl8MjQyNTgwfDMyMTUwNXwxNjMzNTMyNDAwMDAw?clientKey=4d9a69ed-775c-448a-9eae-fa18a49a6d19&utm_source=beat&utm_medium=fest_link&utm_campaign=1639964967.1631554120')
    crow_cook=br.cookies
    p '________'
    br = Hamster::Scraper::Dasher.new(using: :hammer, use_proxy:2)
    br.get('https://widget.afisha.yandex.ru/w/sessions/MjI3Njl8MjQyNTgwfDMyMTUwNXwxNjMzNTMyNDAwMDAw?clientKey=4d9a69ed-775c-448a-9eae-fa18a49a6d19&utm_source=beat&utm_medium=fest_link&utm_campaign=1639964967.1631554120')
    hammer_cook=br.cookies
    #q = br.smash(url: 'https://refactoring.guru/ru/design-patterns/factory-method')
    p '________'
    p cobble_cook
    p crow_cook
    p hammer_cook


  end

  # DOWNLOAD PDF files
  if @arguments[:simple]
    Download.new(limit)
  elsif @arguments[:js42]
    Download_js_court.new(limit)
  elsif @arguments[:court30]
    Court_30.new()
  elsif @arguments[:delete]
    Download.new(limit,delete=@arguments[:delete]) if @arguments[:delete].class==Integer

    # TRANSFER from dev (raw) table to root table all datas
  elsif options[:transfer]
    if options[:tr10]
      # Simple checking for first 10 rows
      start_transfer(limit=10, days=0)
    elsif @arguments[:days]
      # We can put how many days for updated_at
      days = @arguments[:days]
      start_transfer(limit=0, days=days)
    else
      # Transfer all data from table us_courts_start, where not_test = 1
      start_transfer(limit=0, days=0)
    end
  elsif options[:history]
    if options[:history].class==Integer
      start_history_transfer(options[:history])
    else
      start_history_transfer
    end
  elsif options[:divide]
    q=DivideActivities.new()
  elsif options[:md5]
    #court_case = {court_id: 40, case_id: 'B 1602465-B', party_name: 'GIVENS/DANTE/L', party_type:'diffendant'}
    #md5 = PacerMD5.new(data: court_case, table: "party_root")
    q='141:20-cv-01279-TWTHAROLD R. BERKPlaintiff'
    #q+=Date.new(2017, 4, 12).to_s
    #p q
    p Digest::MD5.hexdigest q

  # elsif options[:mech]
  #   url='https://www.seethroughny.net/payrolls/193826001'
  #   agent = Mechanize.new
  #   page = agent.get(url)
  #   File.open('see.html', 'w') { |file| file.write(page.body) }
    elsif options[:conn]
        url='https://www.trec.texas.gov/apps/license-holder-search/?lic_name=ben&lic_hp=&ws=1226&industry=Real+Estate&license_search=Search&showpage=2'
        q = connect_to(url)
        p q.body

  end

end


def parse_myip(body)
  doc = Nokogiri::HTML(body)
  doc.css("[@id='ip-address']")[0].content

end