class Scraper < AbstractScraper
  ORIGIN = "https://public.courts.in.gov"

  def initialize(**options)
    super
    @skip_res = 0
    @take_res = 0
  end

  def scrape(court_item_id, &block)
    raise 'Block must be given' unless block_given?

    do_connect(url: "https://public.courts.in.gov/mycase/#/vw/Search")
    letters = *('A'..'Z')
    letters.each do |let|
      Hamster.logger.info("Letter: #{let}. court_item_id: #{court_item_id}")
      body_src = search({last: let, court_item_id: court_item_id})
      while !body_src["Results"].nil?
        @skip_res = body_src["Skip"]
        @take_res = body_src["Take"]
        body_src["Results"].each do |item| 
          Hamster.logger.info("Processing case id: #{item["CaseNumber"]}")
          inner_page = case_summary(item["CaseToken"])
          yield inner_page
        end

        body_src = next_take
      end
    end
  end

  def download_pdf(url, tries: 100)
    Hamster.logger.info("Processing URL -> #{url}")
    response = safe_connection { Hamster.connect_to(url: url, proxy_filter: @proxy_filter) }
    reporting_request(response)
    raise if response.nil? || response.status != 200
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

  # last - letter from A to Z
  # skip - Item skip
  # take - Item return
  # new_search - If search is new then new_search set true else new_search set false
  
  def search(**params)
    params = params.dup

    @search_params = {
      "Mode": "ByParty",
      "CaseNum": nil,
      "CiteNum": nil,
      "CrossRefNum": nil,
      "First": nil,
      "Middle": nil,
      "Last": (params[:last] ? params[:last].dup : nil),
      "Business": nil,
      "DoBStart": nil,
      "DoBEnd": nil,
      "OANum": nil,
      "BarNum": nil,
      "SoundEx": false,
      "CourtItemID": (params[:court_item_id] ? params[:court_item_id].dup : nil),
      "Categories": nil,
      "Limits": nil,
      "Advanced": false,
      "ActiveFlag": "All",
      "FileStart": nil,
      "FileEnd": nil,
      "CountyCode": nil,
      "NewSearch": true,
      "CaptchaAnswer": nil,
      "Skip": (params[:skip] ? params[:skip].dup : 0),
      "Take": (params[:take] ? params[:take].dup : 100),
      "Sort": "FileDate DESC"
    }

    req_body = @search_params.to_json
    body_src = do_connect(url: "https://public.courts.in.gov/mycase/Search/SearchCases", req_body: req_body, method: :post, accept: 'json')
    body_src.status == 200 ? JSON.parse(body_src.body) : body_src
  end

  def next_take
    @search_params["NewSearch"] = false
    @search_params["Skip"] = @skip_res + @take_res
    req_body = @search_params.to_json
    body_src = do_connect(url: "https://public.courts.in.gov/mycase/Search/SearchCases", req_body: req_body, method: :post, accept: 'json')
    (body_src.status == 200) ? JSON.parse(body_src.body) : body_src
  end

  def case_summary(token)
    body_src = do_connect(url: "https://public.courts.in.gov/mycase/Case/CaseSummary?CaseToken=#{token}", accept: 'json')
    (body_src.status == 200) ? JSON.parse(body_src.body) : body_src
  end
end
