require 'nokogiri'
require 'securerandom'
require_relative 'store'

class Scraper < Hamster::Scraper
  LINK_BASE = "https://www.iardc.org/Lawyer/Search"
  LINK_RESULT = "https://www.iardc.org/Lawyer/SearchResults"
  LINK_AJAX = "https://www.iardc.org/Lawyer/SearchGrid?"
  LINK_DATAILS = "https://www.iardc.org/Lawyer/Details"
  MAX_THREAD = 1
  FOLDER_LAWYER = "layers"
  def initialize(run_id = 0)
    super
    @run_id = run_id
    @folder = "lists"
    @store = Store.new(run_id)
  end

  def get_auth_token
    # get cookie and token
    page = Hamster::connect_to(LINK_BASE)
    set_cookie = page.headers["set-cookie"]
    res = set_cookie.split("; ")
    if res.size > 0
      @cookie = "lang=en-US; " + res[0]
    end
    html = Nokogiri.HTML(page.body)
    @request_cerification_token = html.css("div input[name=\"__RequestVerificationToken\"]").attr("value").value
  end

  def down_lists_to_page id_item, letter
    folder = "layers" + "/" + letter
    #get cookie and token
    post_query = "__RequestVerificationToken=#{@request_cerification_token}&id=#{id_item}"
    header = {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "Accept-Language" => "en-US,en;q=0.5",
      "Accept-Encoding" => "gzip, deflate, br",
      "Referer" => "https://www.iardc.org/Lawyer/Search",
      "Content-Type" => "application/x-www-form-urlencoded",
      "Origin" => "https://www.iardc.org",
      "Connection" => "keep-alive",
      "Upgrade-Insecure-Requests" => "1",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Pragma" => "no-cache",
      "Cache-Control" => "no-cache",
      "User-Agent" => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/92.0'
    }
    header["Content-Length"] = post_query.size.to_s
    header["X-Requested-With"] = "XMLHttpRequest"
    header["Cookie"] = @cookie
    page = Hamster::connect_to(LINK_DATAILS, req_body: post_query, method: :post, headers: header)
    peon.put(subfolder: folder, file: id_item, content: page.body)
  end

  def test_list_store
    list_letters = peon.list(subfolder: FOLDER_LAWYER)
    list_not_found = ('a'..'z').map { |a| a } - list_letters
    oversize = []
    list_letters.each do |letter|
      folder = FOLDER_LAWYER + "/" + letter
      list_file = peon.list(subfolder: folder)
      if list_file.size == 100
        next
      end
      oversize.push([letter => list_file])
    end

    return (oversize.size > 0) ? list_not_found + oversize : list_not_found
  end

  def found_data html
    !html.css("td").to_s.match? /No Data Found/
  end

  def download_last30
    page = Hamster::connect_to(LINK_BASE)
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
    post_query = "__RequestVerificationToken=" + query["__RequestVerificationToken"] + "&IsRecentSearch=true&IncludeFormerNames=false&LastName=&LastNameMatch=Exact&FirstName=&Status=All&LawyerCounty=&City=&State=&Country=&StatusChangeTimeFrame=Last30Days&BusinessLocation=All&County=&JudicialCircuit=&JudicialDistrict=&StatusLastName="

    current_folder = @folder + "/z"

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

    # header["Content-Length"] = post_query.size.to_s
    page = Hamster::connect_to(LINK_RESULT, req_body: post_query, method: :post, headers: header)
    html = Nokogiri.HTML(page.body)
    page_key = html.css("script[nonce]").text.match(/PageKey:\ +\"(.*)\",\r/)
    request_cerification_token = html.css("input[name=\"__RequestVerificationToken\"]").attr("value").value
    header["X-Requested-With"] = "XMLHttpRequest"
    post_query = "PageKey=#{page_key[1]}&LastName=&StatusLastName=&LastNameMatch=0&IncludeFormerNames=false&FirstName=&Status=1&City=&State=&Country=&StatusChangeTimeFrame=0&BusinessLocation=0&County=&LawyerCounty=&JudicialCircuit=&JudicialDistrict=&IsRecentSearch=true&__RequestVerificationToken=#{request_cerification_token}"
    header["Content-Length"] = post_query.size.to_s
    page = Hamster::connect_to(LINK_AJAX + "rows=100", req_body: post_query, method: :post, headers: header)
    html = Nokogiri.HTML(page.body)

    if found_data(html)
      page_count = html.css("div.mvc-grid-pager ul li a[data-page]")[-1].attr("data-page")
      peon.put(file: "z_1.html", content: page.body, subfolder: current_folder)

      (2..page_count.to_i).each do |p|
        begin
          page = Hamster::connect_to(LINK_AJAX + "rows=100&page=" + p.to_s, req_body: post_query, method: :post, headers: header)
          file_name = "z" + "_#{p.to_s}.html"
          peon.put(file: file_name, content: page.body, subfolder: current_folder)
        rescue StandardError => error_down_page
          puts error_down_page.to_s.red
          retry if (count_repeat -= 1) > 0
          count_repeat = 5
          next
        end
      end if page_count.to_i > 1
    end

  end

  def download
    page = Hamster::connect_to(LINK_BASE)
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

    str_query = "__RequestVerificationToken=%s&IsRecentSearch=False&LastName=%s&LastNameMatch=Exact&FirstName=&Status=All&LawyerCounty=&City=&State=&Country=&StatusChangeTimeFrame=Last30Days&BusinessLocation=All&County=&JudicialCircuit=&JudicialDistrict=&StatusLastName="
    #Формируем "очереди" для потоков
    thread_data = Scraper.count_thread({ array: ('a'..'z').map { |n| n } })
    #Запускаем потоки!!!
    threads = []
    thread_data.each do |item|
      threads << Thread.new(item) do |item|
        item.each { |let| thread_call({ letter: let, str_query: str_query, cookie: cookie, query: query }) }
      end
    end
    threads.each(&:join)
    #Завершаем скачивание
  end

  def thread_call **args
    letter = args[:letter]
    str_query = args[:str_query]
    cookie = args[:cookie]
    query = args[:query]

    count_repeat = 5
    begin
      if letter.class == Array
        list_file_found = letter.first.values[0]
        letter = letter.first.keys[0]
      end

      current_folder = @folder + "/" + letter
      post_query = sprintf(str_query, query["__RequestVerificationToken"], letter);
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

      header["Content-Length"] = post_query.size.to_s
      page = Hamster::connect_to(LINK_RESULT, req_body: post_query, method: :post, headers: header)
      html = Nokogiri.HTML(page.body)
      page_key = html.css("script[nonce]").text.match(/PageKey:\ +\"(.*)\",\r/)
      request_cerification_token = html.css("input[name=\"__RequestVerificationToken\"]").attr("value").value
      header["X-Requested-With"] = "XMLHttpRequest"
      post_query = "PageKey=#{page_key[1]}&LastName=#{letter}&StatusLastName=&LastNameMatch=0&FirstName=&Status=1&City=&State=&Country=&StatusChangeTimeFrame=0&BusinessLocation=0&County=&LawyerCounty=&JudicialCircuit=&JudicialDistrict=&IsRecentSearch=false&__RequestVerificationToken=#{request_cerification_token}"
      header["Content-Length"] = post_query.size.to_s
      page = Hamster::connect_to(LINK_AJAX + "rows=100", req_body: post_query, method: :post, headers: header)
      html = Nokogiri.HTML(page.body)
      page_count = html.css("div.mvc-grid-pager ul li a[data-page]")[-1].attr("data-page")
      peon.put(file: letter + "_1.html", content: page.body, subfolder: current_folder)
      (2..page_count.to_i).each do |p|
        begin
          page = Hamster::connect_to(LINK_AJAX + "rows=100&page=" + p.to_s, req_body: post_query, method: :post, headers: header)
          file_name = letter + "_#{p.to_s}.html"
          peon.put(file: file_name, content: page.body, subfolder: current_folder)
        rescue StandardError => error_down_page
          puts error_down_page.to_s.red
          retry if (count_repeat -= 1) > 0
          count_repeat = 5
          next
        end
      end
      # https://www.iardc.org/Lawyer/SearchGrid?page=1&rows=10
    rescue StandardError => error_download
      puts error_download.to_s.red
      retry if (count_repeat -= 1) > 0
    end
  end

  def download_layers
    count_retry = 5
    begin
      id_list = get_letter_ids
      get_auth_token
      id_list.each_key do |letter|
        id_list[letter].each do |id|
          begin
            down_lists_to_page id, letter
          rescue StandardError => error_down_details
            puts error_down_details.to_s.red
            retry if (count_retry -= 1) > 0
            puts "Error Download ( #{id}, #{letter} )".red
            next
          end
        end
      end
    rescue StandardError => error_download_lawyer
      puts error_download_lawyer.to_s.red
      retry if (count_retry -= 1) > 0
      puts "Not give token get_auth_token  or get_letter_ids".red
    end
  end

  def get_letter_ids
    list_letters = peon.list(subfolder: @folder)
    ids_list = {}
    thread_data = Scraper.count_thread(array: list_letters)
    threads = []
    file_error = []
    thread_data.each do |item|
      threads << Thread.new(item) do |item|

        item.each do |let|
          folder = @folder + "/" + let
          files = peon.list(subfolder: folder)
          files.each do |file|
            begin
              get_ids_from_file(file, folder)
            rescue
              file_error << file
              peon.move(from: folder, to: "error_lists/" + folder, file: file)
              next
            end
          end
        end
      end
    end

    threads.each(&:join)
  end

  def get_ids_from_file(file, folder)
    begin
      content = peon.give(file: file, subfolder: folder)
      @store.parse_store_index(content)
      peon.move(from: folder, to: "done_lists/" + folder, file: file)
    rescue Exception => e
      puts e.to_s.red
    end
  end

  def download_description
    arr_index = @store.index_uuid(@run_id).map { |item| { id: item.id, uuid: item.uuid } }
    threads_data = Scraper.count_thread({ array: arr_index })

    threads = []

    threads_data.each_with_index do |item, index|
      threads << Thread.new(item, index) do |item_t, index_t|
        thread_download_layers({ id_list: item_t, letter: index_t })
      end
    end
    threads.each(&:join)

  end

  def Scraper.count_thread(**args)

    letter = args[:array]
    size_letter = letter.size
    thread_data = []
    if (size_letter > 1)
      quotient, modulus = size_letter.divmod(MAX_THREAD)

      # Массив диапозонов
      index_thread_letter = []
      #Массив диапозонов остаточных
      index_thread_letter_modules = []

      $i = 0
      while $i < MAX_THREAD do
        index_thread_letter << { min: (quotient * $i), max: (quotient * $i + quotient) - 1 }
        $i += 1
      end

      if (modulus > 0 && quotient > 0)
        quotient_mod, modulus_mod = modulus.divmod(quotient)
        $i = 0
        index_begin = quotient * MAX_THREAD
        while $i < quotient_mod do
          max_index = (index_begin + ((quotient * $i + quotient) - 1))
          max_index = size_letter -1 if max_index >= size_letter
          index_thread_letter_modules << { min: (index_begin + ($i * quotient)), max: max_index }
          $i += 1
        end

        if (modulus_mod > 0)
          max_index = index_begin + ((quotient_mod * quotient + modulus_mod))
          max_index = size_letter -1 if max_index >= size_letter
          index_thread_letter_modules << { min: (index_begin + (quotient_mod * quotient)), max: max_index }
        end
      end

      #Заполняем массив основными данными
      index_thread_letter.each do |item|
        thread_data << letter[item[:min]..item[:max]]
      end
      #Добиваем остаточными данными
      index_thread_letter_modules.each_with_index do |item, index|
        thread_data[index] += letter[item[:min]..item[:max]]
      end
    else
      thread_data << letter
    end

    return thread_data
  end

  def get_auth_token_thread
    # get cookie and token
    page = Hamster::connect_to(LINK_BASE)
    set_cookie = page.headers["set-cookie"]
    res = set_cookie.split("; ")
    if res.size > 0
      cookie = "lang=en-US; " + res[0]
    end
    html = Nokogiri.HTML(page.body)
    request_cerification_token = html.css("div input[name=\"__RequestVerificationToken\"]").attr("value").value
    return { cookie: cookie, request_cerification_token: request_cerification_token }
  end

  def thread_download_layers(**args)
    id_list = args[:id_list]
    letter = args[:letter]
    count_retry = 5
    begin
      ret_auth = get_auth_token_thread

      id_list.each do |item|
        begin
          down_lists_to_page_thread item[:uuid], letter.to_s, ret_auth
        rescue StandardError => error_down_details
          puts error_down_details.to_s.red
          retry if (count_retry -= 1) > 0
          puts "Error Download ( #{item[:uuid]}, #{letter.to_s} )".red
          next
        end
      end

    rescue StandardError => error_download_lawyer
      puts error_download_lawyer.to_s.red
      retry if (count_retry -= 1) > 0
      puts "Not give token get_auth_token  or get_letter_ids".red
    end
  end

  def down_lists_to_page_thread id_item, letter, auth
    folder = "layers" + "/" + letter
    #get cookie and token
    post_query = "__RequestVerificationToken=#{auth[:request_cerification_token]}&id=#{id_item}"
    header = {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "Accept-Language" => "en-US,en;q=0.5",
      "Accept-Encoding" => "gzip, deflate, br",
      "Referer" => "https://www.iardc.org/Lawyer/Search",
      "Content-Type" => "application/x-www-form-urlencoded",
      "Origin" => "https://www.iardc.org",
      "Connection" => "keep-alive",
      "Upgrade-Insecure-Requests" => "1",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Pragma" => "no-cache",
      "Cache-Control" => "no-cache",
      "User-Agent" => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/92.0'
    }
    header["Content-Length"] = post_query.size.to_s
    header["X-Requested-With"] = "XMLHttpRequest"
    header["Cookie"] = auth[:cookie]
    page = Hamster::connect_to(LINK_DATAILS, req_body: post_query, method: :post, headers: header)
    peon.put(subfolder: folder, file: id_item, content: page.body)

  end

end