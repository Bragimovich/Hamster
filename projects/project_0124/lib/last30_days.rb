# This is "Class" for download and storage pages of last 30 day
class Last30Days < Hamster::Scraper

  LINK_BASE = "https://www.iardc.org/Lawyer/Search"
  FOLDER = "list_last30days"
  LINK_RESULT = "https://www.iardc.org/Lawyer/SearchResults"
  LINK_AJAX = "https://www.iardc.org/Lawyer/SearchGrid?"

  LASTDAY = "Last90Days"

  def initialize(run_id)
    super
    @store = Store.new(run_id)
  end

  def init_vars
    retries = 0

    begin
      proxy = Camouflage.new
      @current_proxy = proxy.swap
      page = Hamster::connect_to(url: LINK_BASE, proxy: @current_proxy)
    rescue Exception => e
      retries += 1
      pp e
      sleep(rand(15))
      retry if retries <= proxy.count
    end

    cookie = nil
    set_cookie = page.headers["set-cookie"]
    res = set_cookie.split("; ")
    if res.size > 0
      cookie = "lang=en-US; " + res[0]
    end

    html = Nokogiri.HTML(page.body)
    query = {}

    html.css("form input").each do |input|
      obj = { input.attr("name") => input.attr("value") }
      query.merge!(obj)
    end
    post_query = "__RequestVerificationToken=" + query["__RequestVerificationToken"] + "&IsRecentSearch=true&IncludeFormerNames=false&LastName=&LastNameMatch=Exact&FirstName=&Status=All&LawyerCounty=&City=&State=&Country=&StatusChangeTimeFrame=#{LASTDAY}&BusinessLocation=All&County=&JudicialCircuit=&JudicialDistrict=&StatusLastName="
    [post_query, cookie]
  end

  def found_data html
    !html.css("td").to_s.match? /No Data Found/
  end

  #Download index pages
  def download

    post_query, cookie = init_vars


      #It is folder where put index files
      current_folder = FOLDER

      header = {
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language" => "en-US,en;q=0.5",
        "Accept-Encoding" => "gzip, deflate, br",
        "Referer" => "https://www.iardc.org/Lawyer/Search",
        "Content-Type" => "application/x-www-form-urlencoded",
        "Origin" => "https://www.iardc.org",
        "Connection" => "keep-alive",
        "Cookie" => cookie,
        "Upgrade-Insecure-Requests" => "1",
        "Sec-Fetch-Dest" => "document",
        "Sec-Fetch-Mode" => "navigate",
        "Sec-Fetch-Site" => "same-origin",
        "Sec-Fetch-User" => "?1",
        "Pragma" => "no-cache",
        "Cache-Control" => "no-cache",
        "User-Agent" => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/92.0'
      }

      page = Hamster::connect_to(LINK_RESULT, req_body: post_query, method: :post, headers: header, proxy: @current_proxy)



    html = Nokogiri.HTML(page.body)
    page_key = html.css("script[nonce]").text.match(/PageKey:\ +\"(.*)\",\r/)
    request_cerification_token = html.css("input[name=\"__RequestVerificationToken\"]").attr("value").value
    header["X-Requested-With"] = "XMLHttpRequest"

    post_query = "PageKey=#{page_key[1]}&LastName=&StatusLastName=&LastNameMatch=0&IncludeFormerNames=false&FirstName=&Status=1&City=&State=&Country=&StatusChangeTimeFrame=#{LASTDAY}&BusinessLocation=0&County=&LawyerCounty=&JudicialCircuit=&JudicialDistrict=&IsRecentSearch=true&__RequestVerificationToken=#{request_cerification_token}"
    header["Content-Length"] = post_query.size.to_s
    page = Hamster::connect_to(LINK_AJAX + "page=1&rows=100&sort=date-admitted&order=desc", req_body: post_query, method: :post, headers: header, timeout: 20, proxy: @current_proxy)
    html = Nokogiri.HTML(page.body)

    if found_data(html)
      page_count = html.css("div.mvc-grid-pager ul li a[data-page]")[-1].attr("data-page")
      peon.put(file: "1.html", content: page.body, subfolder: current_folder)

      (2..page_count.to_i).each do |p|
        begin
          page = Hamster::connect_to(LINK_AJAX + "page=#{p.to_s}&rows=100&sort=date-admitted&order=desc", req_body: post_query, method: :post, headers: header, proxy: @current_proxy)
          file_name = "#{p.to_s}.html"
          peon.put(file: file_name, content: page.body, subfolder: current_folder)
        rescue StandardError => error_down_page
          puts error_down_page.to_s.red
          retry if (count_repeat -= 1) > 0
          count_repeat = 5
          next
        end
      end if page_count.to_i > 1
    end
    get_letter_ids

  end

  def get_ids_from_file(file)
    begin
      content = peon.give(file: file, subfolder: FOLDER)
      @store.parse_store_index(content)
      peon.move(from: FOLDER, to: "done_lists/" + FOLDER, file: file)
    rescue Exception => e
      puts e.to_s.red
    end
  end

  def get_letter_ids
    ids_list = peon.list(subfolder: FOLDER)

    ids_list.each do |file|
      begin
        puts "parse file: #{file}"
        get_ids_from_file(file)
      rescue
        file_error << file
        peon.move(from: FOLDER, to: "error_lists/" + FOLDER, file: file)
        next
      end
    end
  end

  def move_to_main_table
    @store.move_to_main_table
  end

end
