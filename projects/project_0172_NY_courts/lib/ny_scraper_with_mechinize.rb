

def gathering(scrape_date=nil, update=0)

  #crowbar = Dasher.new(:using=>:crowbar, pc:1, headless:false)
  # q = crowbar.get(SEARCH_URL)
  # @agent = crowbar.connection



  peon = Peon.new(storehouse)
  last_court_number = nil

  last_place_file = 'last_place'

  if "#{last_place_file}.gz".in? peon.give_list() and update == 0
    last_date, last_court_number, = peon.give(file:last_place_file).split('|')
    scrape_date = Date.parse(last_date)
  end

  cobble = Dasher.new(:using=>cobble)
  trying = 0

  scrape_date = Date.today()-1 if scrape_date.class!=Date

  COURTS.each_key do |court_number|
    if !last_court_number.nil?
      if court_number.to_s!=last_court_number
        next
      elsif court_number.to_s==last_court_number
        last_court_number=nil
      end
    end
    p "Court: #{court_number}"
    counter_agent = 0
    while scrape_date>Date.new(2021,8,31)
      p scrape_date
      counter_agent = remake_agent if (counter_agent>3) or (@agent.nil?)
      return if @captcha_number>999
      counter_agent += 1

      filed_date = "#{scrape_date.month.to_s.rjust(2, '0')}/#{scrape_date.day.to_s.rjust(2, '0')}/#{scrape_date.year}"

      query = {
        'txtFilingDate' => filed_date,
        'selCountyCourt' => court_number,# court_id,
        'btnSubmit' => 'Search'
      }
      page = @agent.post 'https://iapps.courts.state.ny.us/nyscef/CaseSearch?task=modify', query
      p page.body
      list_cases = parse_list_case_url(page.body)
      p check_cases(page.body)
      if check_cases(page.body)
        scrape_date = scrape_date - 1
        redo
      end

      if list_cases.empty?
        return if trying>5
        trying+=1
        p "trying: #{trying}"
        sleep 6**trying
        redo
      end

      existing_case_ids = existing_cases(list_cases.keys)

      list_cases.each do |case_id, docket_id|
        next if case_id.in?(existing_case_ids)
        p case_id

        #@agent.get(CASE_DETAILS+docket_id)  #@agent.current_page.dup
        details_link = CASE_DETAILS+docket_id
        page_detail = cobble.get(details_link)

        case_detail = CaseDetail.new(page_detail, scrape_date, @scrape_dev_name, details_link)
        #p case_detail
        # p case_detail.case_info
        # p case_detail.case_parties
        #case_id = link_case.split('?docketId=')[-1].split('&')[0]

        #@agent.get(CASE_DOCUMENTS+docket_id)
        document_link = CASE_DOCUMENTS+docket_id
        page_document = cobble.get(document_link)
        document_list = DocumentList.new(page_document, @scrape_dev_name, document_link)
        #p document_list.case_activities
        put_all_in_db(case_detail, document_list)

      end

      peon.put(content: "#{scrape_date}|#{court_number}|", file: last_place_file)

      scrape_date = scrape_date - 1
      trying = 0
    end
  end

end



def check_down
  cobble = Dasher.new(:using=>:crowbar, pc:1)
  link = 'https://iapps.courts.state.ny.us/nyscef/CaseDetails?docketId=YXCNZreX4tgqaU_PLUS_2nVO_PLUS_hw=='
  link = 'https://iapps.courts.state.ny.us/nyscef/CaseDetails?docketId=8xjTc1e1GzPZImsGqh_PLUS_9ow=='
  link = 'https://iapps.courts.state.ny.us/nyscef/CaseDetails?docketId=yGRkHOXgn5mQdBiOlzhfLQ=='
  # page_detail = cobble.get link
  # case_detail = CaseDetail.new(page_detail, Date.new(), @scrape_dev_name, link)
  # p case_detail.case_judgement

  document_link = 'https://iapps.courts.state.ny.us/nyscef/DocumentList?docketId=_PLUS_g_PLUS_g5EyHL9YC4N0cNKNqcg==&display=all'
  page_document = cobble.get(document_link)
  p page_document
  document_list = DocumentList.new(page_document, @scrape_dev_name, document_link)
  p document_list.case_activities
  #p case_detail.case_info
end


def remake_agent
  @agent = Mechanize.new
  @agent.user_agent_alias = Mechanize::AGENT_ALIASES.keys.sample
  @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
  curr_proxy = proxies
  @agent.set_proxy(curr_proxy[:addr],
                   curr_proxy[:port],
                   curr_proxy[:login],
                   curr_proxy[:password])

  #response = @agent.get(SEARCH_URL)
  response = @agent.get("https://iapps.courts.state.ny.us/nyscef/NyscefReCaptcha")
  # crowbar = Dasher.new(:using=>:crowbar, pc:1, headless:false)
  # page = crowbar.get(SEARCH_URL)
  # @agent = crowbar.connection
  p response.body
  #until !captcha_page?
  #handle_captcha_in_agent #if captcha_page? #if !page.nil?
  @captcha_number+=1
  0
end


def handle_captcha
  options = {
    pageurl: SEARCH_URL,
    googlekey: '6LfmfjYUAAAAAMujuZ5wPlqjGqVYr7Ie4okh5aF-'
  }
  #
  captcha_form = @agent.current_page.form_with(name: 'captcha_form')
  decoded_captcha = @two_captcha.decode_recaptcha_v2!(options)
  captcha_form.field_with(name: 'g-recaptcha-response').value = decoded_captcha.text
  captcha_form.submit

end

def handle_captcha_in_agent
  options = {
    pageurl: SEARCH_URL,
    googlekey: '6LfmfjYUAAAAAMujuZ5wPlqjGqVYr7Ie4okh5aF-'
  }
  #
  @agent.get(SEARCH_URL)
  decoded_captcha = @two_captcha.decode_recaptcha_v2!(options)

  url = "https://iapps.courts.state.ny.us/nyscef/NyscefReCaptcha"


  query = {
    'g-recaptcha-response' => decoded_captcha.text,
  }
  p query
  page = @agent.post(url, query)
  p page.body
  #captcha_form.field_with(name: 'g-recaptcha-response').value = decoded_captcha.text
  #captcha_form.submit

end