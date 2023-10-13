require_relative '../lib/abstract_scraper.rb'

# This is "Class" for download and storage pages of last year
class UpdateLastYear < AbstractScraper


  LINK_BASE = "https://www.iardc.org/Lawyer/Search"
  FOLDER_INDEX = "index_last_year"
  FOLDER_DISC = "desc_last_year"
  LINK_RESULT = "https://www.iardc.org/Lawyer/SearchResults"
  LINK_AJAX = "https://www.iardc.org/Lawyer/SearchGrid?"
  LINK_PRINT_DETAIL = "https://www.iardc.org/Lawyer/PrintableDetails"

  def initialize(option = {})
    super
    Hamster.report to: "Mikhail Golovanov", message: "#124: Start #{ DateTime.now.to_s }", use: :slack
    @count_error = 5
    @run_id = option["run_id"] unless option["run_id"].nil?
    @run = Illinois_runs.find(@run_id)
    @store = Parser.new(@run_id)

    begin
      init_vars
      header(accept: "html")

      if @run.status == "process_upd_years"
        download
        @run.status = "list_dwn_ok"
        @run.save
        @count_error = 5
      end

      if @run.status == "list_dwn_ok"
        get_letter_ids
        @run.status = "list_save_ok"
        @run.save
        @count_error = 5
      end

      if @run.status == "list_save_ok"
        details
        @run.status = "det_dwn_ok"
        @run.save
        @count_error = 5
      end

      if @run.status == "det_dwn_ok"
        datails_save
        @run.status = "det_save_ok"
        @run.save
        @count_error = 5
      end

      if @run.status == "det_save_ok"
        @store.move_to_main_table
        @run.status = "finish"
        @run.save
        @count_error = 5
      end

    rescue StandardError => e
      message = e.backtrace_locations.to_s.red
      puts message
      retry if (@count_error -= 1) > 0
      @run.status = "finish_error"
      @run.save
      Hamster.report to: "Mikhail Golovanov", message: "#124: #{message}", use: :slack
    end

    Hamster.report to: "Mikhail Golovanov", message: "#124: Files Error: #{ @file_error.join(";").to_s }", use: :slack
    Hamster.report to: "Mikhail Golovanov", message: "#124: Finish #{ DateTime.now.to_s }", use: :slack
  end

  def init_vars
    connect_to(url: LINK_BASE)

    html = @content_html
    @query = {
      "IsRecentSearch" => "true",
      "IncludeFormerNames" => "false",
      "LastName" => "",
      "LastNameMatch" => "Exact",
      "FirstName" => "",
      "Status" => "All",
      "LawyerCounty" => "",
      "City" => "",
      "State" => "",
      "Country" => "",
      "StatusChangeTimeFrame" => "LastYear",
      "BusinessLocation" => "All",
      "County" => "",
      "JudicialCircuit" => "",
      "JudicialDistrict" => "",
      "StatusLastName" => ""
    }

    html.css("form input").each do |input|
      obj = { input.attr("name") => input.attr("value") }
      @query.merge!(obj)
    end

    @query
  end

  def post_query
    @query.map { |index, item| "#{CGI::escape(index)}=#{CGI::escape(item)}" }.join("&")
  end

  def found_data html
    !html.css("td").to_s.match? /No Data Found/
  end

  #Download index pages
  def download
    header(accept: "url_post")
    #It is folder where put index files
    current_folder = FOLDER_INDEX

    connect_to(url: LINK_RESULT, req_body: post_query, method: :post)
    html = @content_html
    page_key = html.css("script[nonce]").text.match(/PageKey:\ +\"(.*)\",\r/)
    request_cerification_token = html.css("input[name=\"__RequestVerificationToken\"]").attr("value").value

    header(accept: "url_post")
    @headers.merge!({ "X-Requested-With" => "XMLHttpRequest" })

    @query["__RequestVerificationToken"] = request_cerification_token
    @query["PageKey"] = page_key[1]
    @query["StatusChangeTimeFrame"] = "2"
    @query["BusinessLocation"] = "0"
    @query["IsRecentSearch"] = "true"
    @query["LastNameMatch"] = "0"
    @headers["Content-Length"] = post_query.size.to_s
    connect_to(url: LINK_AJAX + "rows=100", req_body: post_query, method: :post)
    html = @content_html

    if found_data(html)
      page_count = html.css("div.mvc-grid-pager ul li a[data-page]")[-1].attr("data-page")
      peon.put(file: "last_update_year_1.html", content: @content_raw_html, subfolder: current_folder)

      (2..page_count.to_i).each do |p|
        begin
          connect_to(url: LINK_AJAX + "rows=100&page=" + p.to_s, req_body: post_query, method: :post)
          file_name = "last_update_year_#{p.to_s}.html"
          peon.put(file: file_name, content: @content_raw_html, subfolder: current_folder)
        rescue StandardError => error_down_page
          puts error_down_page.to_s.red
          retry if (count_repeat -= 1) > 0
          count_repeat = 5
          next
        end
      end if page_count.to_i > 1
    end

  end

  def get_ids_from_file(file)
    begin
      content = peon.give(file: file, subfolder: FOLDER_INDEX)
      @store.parse_store_index(content)
      peon.move(from: FOLDER_INDEX, to: "done_lists/" + FOLDER_INDEX, file: file)
    rescue Exception => e
      message e.backtrace.to_s.red
      puts message
      Hamster.report to: "Mikhail Golovanov", message: "#124: Finish #{ message.to_s }", use: :slack
      init_vars
      header(accept: "html")
      retry if (@count_error -= 1) > 0
    end
  end

  def get_letter_ids
    ids_list = peon.list(subfolder: FOLDER_INDEX)

    ids_list.each do |file|
      begin
        @count_error = 5
        get_ids_from_file(file)
      rescue
        @file_error << file
        peon.move(from: FOLDER_INDEX, to: "error_lists/" + FOLDER_INDEX, file: file)
        next
      end
    end
  end

  def move_to_main_table
    @store.move_to_main_table
  end

  def details
    index_uuid_db = @store.index_uuid

    raise "Indexes are empty" if index_uuid_db.size == 0

    index_uuid_db.each do |item|
      connect_to(url: LINK_PRINT_DETAIL + "/#{item.uuid}")
      filename = "#{item.uuid}.html"
      peon.put(subfolder: FOLDER_DISC, file: filename, content: @content_raw_html)
    end
  end

  def datails_save

    list_files = peon.give_list(subfolder: FOLDER_DISC)

    list_files.each do |file|
      content = peon.give(subfolder: FOLDER_DISC, file: file)
      hash = @store.parse_lawyers content
      hash[:uuid] = file.to_s.split(".")[0]
      hash[:data_source_url] = LINK_PRINT_DETAIL + "/#{hash[:uuid]}"
      @store.save_to_db hash
      peon.move(from: FOLDER_DISC, to: "done_lists/" + FOLDER_DISC, file: file)
    end
  end
end
