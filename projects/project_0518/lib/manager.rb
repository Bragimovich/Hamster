require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper = Scraper.new
    @run_id = keeper.run_id.to_s
  end
  
  def download
    @two_captcha = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)
    cookie_value, case_type_tab_selection_request  = initial_requests
    already_inserted_folders = fetch_downloaded_files
    case_types_array         = parser.fetch_case_types(case_type_tab_selection_request.body)
    case_types_array         = case_array_filtered(case_types_array, already_inserted_folders)
    
    case_types_array.each do |case_type|
      all_invertals = get_slice_array(case_type)
      all_invertals.each do |interval|
        start_date = get_date(interval.first)
        end_date   = get_date(interval.last)

        cookie_value, case_type_tab_selection_request = initial_requests
        
        begin_date_x_value, end_date_x_value = parser.fetch_date_x_value(case_type_tab_selection_request.body)
        
        beign_date_response  = scraper.date_value_request(begin_date_x_value, cookie_value, start_date, "Begin")
        end_date_response = scraper.date_value_request(end_date_x_value, cookie_value, end_date, "End")

        case_type_dropdown_x_value, case_type_dropdown_id = parser.get_values_for_case_types(case_type_tab_selection_request.body)
        
        case_type_selection_response = scraper.case_type_selection_request(case_type_dropdown_x_value, cookie_value, case_type_dropdown_id, case_type)
        
        x_value    = parser.form_x_value(case_type_tab_selection_request.body)
        inner_method_request = scraper.inner_method_request(x_value, cookie_value, case_type, start_date, end_date)
        
        final_outer_page_response = scraper.final_outer_page_request(cookie_value)
        
        download_inner_pages(final_outer_page_response, case_type, cookie_value)
        
        pages_links = parser.get_pagination_links(final_outer_page_response.body)
        pages_links.each do |inner_page_link|
          pagination_response = scraper.pagination_request(inner_page_link, cookie_value)
          download_inner_pages(pagination_response, case_type, cookie_value)
        end
      end
    end
  end

  def store
    @md5_hash_array = []
    category_folders = peon.list(subfolder: run_id) rescue []
    category_folders.each do |category|
      files_page = peon.give_list(subfolder: "#{run_id}/#{category}")
      files_page.each do|file|
        puts "============================    CATEGORY #{category}    =================== FILE   #{file}    ========="
        case_file  = peon.give(subfolder: "#{run_id}/#{category}", file: file)
        data_array = parser.parse(case_file, run_id)
        @md5_hash_array << data_array[0][0][:md5_hash]
        store_data(data_array)
        update_touch_run_id if @md5_hash_array.count > 5000
      end
    end
    update_touch_run_id
    keeper.mark_deleted
    keeper.finish
  end

  private

  def update_touch_run_id
    keeper.update_touch_id(@md5_hash_array)
    @md5_hash_array = []
  end

  def get_slice_array(type)
    type.squish == 'TR' ?  (Date.parse("01-01-2016")..(Date.today)).map(&:to_date).each_slice(10) : (Date.parse("01-01-2016")..(Date.today)).map(&:to_date).each_slice(120)
  end

  def get_date(interval)
    interval.to_s.split('-').rotate.join('/')
  end

  def download_inner_pages(response, case_type, cookie_value)
    sub_folder               = "#{run_id}/#{case_type.squish}"
    already_downloaded_files =  peon.give_list(subfolder: sub_folder) rescue []
    inner_links_array        = parser.get_inner_links_for_pagination(response.body, case_type)
    inner_links_array.each do |link|
      file_name = link[1].scan(/\w+/).join
      next if already_downloaded_files.include? (file_name + '.gz')
      response = scraper.inner_page_request(link[0], cookie_value)
      save_file(response.body, file_name, sub_folder)
    end
  end

  def initial_requests
    landing_page_response = scraper.landing_page
    cookie_value = get_cookie(landing_page_response)
    
    x_value = parser.find_x_value(landing_page_response.body)
    redirect_using_id_request = scraper.redirect_using_id(x_value, cookie_value)

    url_redirects_request = scraper.url_redirects(cookie_value)
    form_id, x_value, captcha_image_url = parser.get_values(url_redirects_request.body)
    
    ajax_location = captcha_handling(captcha_image_url, cookie_value, x_value, form_id)

    main_page_request = scraper.get_main_page(cookie_value, ajax_location)
    
    number_results_dropdown_x_value, number_results_dropdown_id = parser.increase_per_page_records(main_page_request.body)
    
    increase_per_page_records_count_request = scraper.increase_per_page_records_count(number_results_dropdown_x_value, cookie_value, number_results_dropdown_id)
    
    case_type_tab_x_value, case_type_tab_id = parser.case_type_tab_selection(main_page_request.body)
    
    case_type_tab_selection_request = scraper.case_type_tab_selection(case_type_tab_x_value, cookie_value, case_type_tab_id)
    
    [cookie_value, case_type_tab_selection_request]
  end

  def get_cookie(response)
    response.headers['set-cookie'].split(";").first
  end

  def captcha_handling(captcha_image_url, cookie_value, x_value, form_id)
    captcha_image_response = scraper.captcha_request(captcha_image_url, cookie_value)
    captcha = solve_captcha(captcha_image_response)
    post_captcha_request_response = scraper.post_captcha_request(cookie_value, captcha.text, x_value, form_id)
    ajax_location = post_captcha_request_response.headers['ajax-location']
    captcha_redirect_request = scraper.captcha_redirect(cookie_value, ajax_location)
    captcha_redirect_request.headers['location']
  end

  def solve_captcha(captcha_image_response, retries = 5)
    begin
      solution = ''
      (1..5).map{
        solution = two_captcha.decode(raw: captcha_image_response.body)
        break if solution.api_response.include? 'OK'
      }
      solution
    rescue StandardError => e
      raise if retries <= 1
      solve_captcha(captcha_image_response, retries - 1)
    end
  end

  def case_array_filtered(case_types_array, already_inserted_folders)
    case_types_array.reject { |e| already_inserted_folders.include? e.squish }
  end

  def fetch_downloaded_files
    peon.list(subfolder: run_id).sort[0..-2]  rescue []
  end

  def store_data(data_array)
    keeper.insert_data(data_array[0], IlCckcCaseInfo) unless data_array[0].empty?
    keeper.insert_data(data_array[1], IlCckcCaseParty) unless data_array[1].empty?
    keeper.insert_data(data_array[2], IlCckcCaseJudgement) unless data_array[2].empty?
    keeper.insert_data(data_array[3], IlCckcCaseActivities) unless data_array[3].empty?
  end

  def save_file(content, file_name, subfolder)
    peon.put content: content, file: file_name, subfolder: subfolder
  end

  attr_accessor :keeper, :parser, :run_id, :scraper, :two_captcha

end
