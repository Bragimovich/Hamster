# frozen_string_literal: true

class Scraper < Hamster::Scraper

  SEARCH_URL = 'https://iapps.courts.state.ny.us/nyscef/CaseSearch?TAB=courtDateRange'
  CASE_DETAILS = 'https://iapps.courts.state.ny.us/nyscef/CaseDetails?docketId='
  CASE_DOCUMENTS = 'https://iapps.courts.state.ny.us/nyscef/DocumentList?docketId='


  def initialize(**args)
    super
    # run_id_class = RunId.new()
    # @run_id = run_id_class.run_id
    @scrape_dev_name = 'Maxim G'
    @captcha_number = 0
    @two_captcha = TwoCaptcha.new('3faa98b3c9e2254ebe22a3eb7caca3c2', timeout:200, polling:5)
    p @two_captcha.balance
    if args[:store]
      begin
        gathering()
      rescue Exception => e
        rescue_method(e)
      end
    elsif args[:update]
      court_number = args[:court] || nil
      scrape_date = args[:date] || nil
      begin
        unless scrape_date.nil?
          first_scrape_date = Date.parse(scrape_date)
        else
          first_scrape_date = Date.today() - 1
        end
      rescue
        p 'BAD date!!! Type YYYY-MM-DD'
      end

      begin
        gathering(1,first_scrape_date, court_number )
      rescue Exception => e
        rescue_method(e)
      end

    elsif args[:old_amount]==1
      get_from_old_urls
      #download_pdf()
    elsif args[:check]==1
      download_pdf
    elsif args[:browser]==1
      #remake_agent
      get_list_cases_from_browser
    end

    # deleted_for_not_equal_run_id(@run_id)
    # run_id_class.finish
  end

  def rescue_method(e)
    mess = "Captcha_number: #{@captcha_number}|#{@two_captcha.balance} \nError: #{e}"
    Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
    p mess
    @browser.close if !@browser.nil?
    @hammer_case.close if !@hammer_case.nil?
    exit 0
  end

  def gathering(update=0, first_permanent_scrape_date=nil, first_court_number=nil)
    datetime_of_cycle = DateTime.now()
    peon = Peon.new(storehouse)

    case update
    when 0
      final_scrape_date = Date.new(2021,1,1)
    when 3
      final_scrape_date = Date.today - 3
    else
      final_scrape_date = Date.new(2021,1,1)
    end

    last_place_file = 'last_place'

    if "#{last_place_file}.gz".in? peon.give_list() and update == 0
      last_scraping_date, first_court_number, = peon.give(file:last_place_file).split('|')
      first_permanent_scrape_date = Date.parse(last_scraping_date)
    end

    @hammer_case = Dasher.new(:using=>:hammer, pc:1, headless:true)
    trying = 0
    first_permanent_scrape_date = Date.today()-1 if first_permanent_scrape_date.class!=Date

    hammer = Dasher.new(:using=>:hammer, pc:1, headless:true)
    #first_court_number = '100'
    COURTS.each_key do |court_number|
      if !first_court_number.nil?
        if court_number.to_s != first_court_number.to_s
          next
        elsif court_number.to_s == first_court_number.to_s
          first_court_number=nil
        end
      end
      p "Court: #{court_number}"

      scrape_date = first_permanent_scrape_date
      while_scrape_date = scrape_date - 6

      existing_dates = get_existing_dates(court_number)


      while while_scrape_date>final_scrape_date
        counter_browser = 0
        hash_cases = {}
        while_scrape_date = scrape_date - 5
        while scrape_date>while_scrape_date
          p scrape_date
          if scrape_date.in?(existing_dates)
            while_scrape_date = while_scrape_date -1
            scrape_date = scrape_date - 1
            redo
          end


          if @captcha_number>500
            hours = (DateTime.now() - datetime_of_cycle)*24
            mess = "Captcha:#{@captcha_number}, for #{hours} hours, Balance: #{@two_captcha.balance}"
            Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
            hammer.close if !hammer.nil?
            @hammer_case.close if !@hammer_case.nil?
            exit 0
          end


          if counter_browser>10 #todo 7
            hammer.connect
            counter_browser=0
          end
          hammer.get(SEARCH_URL)
          sleep 5
          @browser = hammer.connection

          begin
            if captcha_page_html(@browser.body)
              handle_captcha_in_browser
            end
          rescue Exception =>e
            mess = "Captcha_number: #{@captcha_number}|#{@two_captcha.balance} \nError: #{e}"
            Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
            p mess
            hammer.close if !hammer.nil?
            @hammer_case.close if !@hammer_case.nil?
            redo
          end

          hash_cases[scrape_date] = get_list_cases_from_browser(scrape_date, court_number)

          if check_cases(@page_with_cases)
            while_scrape_date = while_scrape_date -1
            scrape_date = scrape_date - 1
            counter_browser+=1
            redo
          end

          if hash_cases[scrape_date].empty?
            if check_cases_url(@page_with_cases)
              scrape_date = scrape_date - 1
              counter_browser+=1
              @browser.close
              redo
            end
            hammer.connect
            @browser = hammer.connection
            return if trying>3
            trying+=1
            p "trying: #{trying}"
            sleep 3**trying
            redo
          end

          scrape_date = scrape_date - 1
          @browser.close
          trying = 0
        end

        hammer.close
        @hammer_case.connect

        hash_cases.each do |scrape_date_db, list_cases|
          existing_case_ids = existing_cases(list_cases.keys)
          trying_cases = 0
          list_cases.each do |case_id, docket_id|
            next if case_id.in?(existing_case_ids)
            p case_id

            #@agent.get(CASE_DETAILS+docket_id)  #@agent.current_page.dup
            details_link = CASE_DETAILS+docket_id

            page_detail = @hammer_case.get(details_link)
            case_detail = CaseDetail.new(page_detail, scrape_date_db, @scrape_dev_name, details_link)
            @hammer_case.connection.close
            #p case_detail
            # p case_detail.case_info
            # p case_detail.case_parties
            #case_id = link_case.split('?docketId=')[-1].split('&')[0]
            sleep 0.1
            #@agent.get(CASE_DOCUMENTS+docket_id)
            document_link = CASE_DOCUMENTS+docket_id
            page_document = @hammer_case.get(document_link)
            document_list = DocumentList.new(page_document, @scrape_dev_name, document_link)
            @hammer_case.connection.close
            #p document_list.case_activities
          rescue
            exit 0 if trying_cases>5
            trying_cases+=1
            redo
          else
            put_all_in_db(case_detail, document_list)
            sleep 0.2
          end
        end

        @hammer_case.close

        peon.put(content: "#{scrape_date}|#{court_number}|", file: last_place_file)
      end
      first_permanent_scrape_date = Date.today() - 1
    end
    peon.move(file: last_place_file)

  end

  def checking

    hammer = Dasher.new(:using=>:hammer, pc:1, headless:true)#, query: query, headless:false)
    q = hammer.get(SEARCH_URL)
    p q
    sleep 300
  end


  def captcha_page?
    @agent.current_page.form_with(name: 'captcha_form') or @agent.current_page.css('noscript')[0].content.split(' ')[0]=='Please'
  end




  def get_list_cases_from_browser(scrape_date=(Date.today()-1), court_number=25)
    filed_date = "#{scrape_date.month.to_s.rjust(2, '0')}/#{scrape_date.day.to_s.rjust(2, '0')}/#{scrape_date.year}"
    court_name = COURTS[court_number][:court_name]
    waiter = 0
    begin
      @browser.screenshot(path: "NY_4.png")
      @browser.at_css("select[id='selCountyCourt']").focus.click.type(court_name.split(' ')[0]).click
      sleep 0.2
      @browser.at_css("input[id='txtFilingDate']").focus.type(filed_date)
      sleep 0.2
      @browser.at_css("input[class='BTN_Green']").focus.click
      sleep 2.5
      @page_with_cases = @browser.body.dup
      list_cases = parse_list_case_url(@page_with_cases)
    rescue Exception => e
      p e
      return [] if waiter>3
      waiter +=1
      sleep(3*waiter)
      retry
    end

    if @browser.at_css("span[class='pageNumbers']")
      list_cases.merge(cases_on_next_page)
    end
    list_cases
  end

  def cases_on_next_page
    last_page = parse_last_page(@browser.body)
    list_cases = {}
    page = 1
    while page!=last_page
      page+=1
      url = "https://iapps.courts.state.ny.us/nyscef/CaseSearchResults?PageNum=#{page}"
      @browser.go_to(url)
      list_cases.merge(parse_list_case_url(@browser.body))
    end
    list_cases
  end

  def handle_captcha_in_browser
    options = {
      pageurl: SEARCH_URL,
      googlekey: '6LfmfjYUAAAAAMujuZ5wPlqjGqVYr7Ie4okh5aF-'
    }


    decoded_captcha = @two_captcha.decode_recaptcha_v2!(options)
    @captcha_number+=1
    @browser.screenshot(path: "NY_1.png")
    js_script = "document.getElementById('g-recaptcha-response').innerHTML='#{decoded_captcha.text}';"
    @browser.execute(js_script)
    @browser.execute("onCaptchaSolved()")
    @browser.screenshot(path: "NY_2.png")
    sleep 7
    @browser.go_to(SEARCH_URL)
    @browser.screenshot(path: "NY_3.png")
    sleep 3
  end


  def get_from_old_urls
    hammer = Dasher.new(:using=>:hammer)
    limit = 1000

    last_place_file = 'last_page_amount'
    last_page = 0
    last_court_id = nil
    if "#{last_place_file}.gz".in? peon.give_list()
      last_page, last_court_id, = peon.give(file:last_place_file).split(':').map { |i| i.to_i }
    end

    COURTS.each_value do |court|
      court_id = court[:id]
      if !last_court_id.nil?
        if court_id!=last_court_id
          next
        elsif court_id==last_court_id
          last_court_id=nil
        end
      end


      page = last_page
      last_page = 0


      p "Court_id: #{court_id}"
      loop do
        p "Page: #{page}"
        offset = page*limit
        case_links = []
        USCaseInfo.where(court_id:court_id).where("DATE(case_filed_date) > ?", Date.new(2019,1,1)).limit(limit).offset(offset).map { |row| case_links.push row.data_source_url }

        existing_links = existing_cases_judgement(case_links)

        case_links.each do |link|
          next if link.in?(existing_links)
          html_page = hammer.get(link)

          scrape_date = nil


          case_detail = CaseDetail.new(html_page, scrape_date, @scrape_dev_name, link, court_id)

          put_amount_in_db(case_detail)

        end
        peon.put(content: "#{page}:#{court_id}:", file: last_place_file)
        page=+1
        break if case_links.length<limit
      end
    end
  end

  private
  def proxies
    [
      { addr: '186.179.7.194', port: 8271, login: 'noihtpkm-dest', password: 'h4kbu0kn5ruo' },
      { addr: '196.16.111.26', port: 8000, login: 'mFsNch', password: 'TzbonH' },
    ].sample
  end

end