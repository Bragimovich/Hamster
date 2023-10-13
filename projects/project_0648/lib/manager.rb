# frozen_string_literal: true
# Note: pdf links and inner links would be expire after some time. and will be changing every time we get these, and may be some how linked with cookie

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester

  MAIN_URL = 'https://myeclerk.myorangeclerk.com/Cases/Search'
  COURT_ID = '92'

  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @s3 = AwsS3.new(bucket_key = :us_court)
    @s3_res = Aws::S3::Resource.new
    @run_id = keeper.run_id
  end

  def download
    year_array, year_month_array, year_month_day_array, year_month_day_letter_array = keeper.already_processed_dates
    @already_uploaded_or_processed_ids = uploaded_or_inserted_ids
    case_types = get_case_types
    midpoint = case_types.count/2
    letter = ''
    logger.info "Found #{case_types.count} case_types"
    case_types.each do |case_type|
      logger.info "processing case_type #{case_type}"
      (22..22).each do |year|
        # spliting over years
        next if year_array.include? [year, case_type]
        start_date = "1/1/#{year}"
        end_date = "12/31/#{year}" # no any other dates result found checked
        links, cookie, bad_request = get_inner_page_links(start_date, end_date, letter, case_type)
        if bad_request 
          keeper.insert_scrape_date_track({year: year, case_type: case_type, bad_request: true})
        elsif links.count == 0
          keeper.insert_scrape_date_track({year: year, case_type: case_type, no_links: true})
        elsif links.count < 500
          flag = process_links(start_date, end_date, letter, case_type, links, cookie)
          keeper.insert_scrape_date_track({year: year, case_type: case_type, is_completed: true}) if flag
          keeper.insert_scrape_date_track({year: year, case_type: case_type, processing_error: true}) unless flag
        else
          # i.e links are more than 500
          # current_month = Time.now.strftime("%m").to_i
          (1..12).each do |month|
            # spliting over months
            next if year_month_array.include? [year, month, case_type]
            last_day = Date.new(year, month, -1).day
            start_date = "#{month}/1/#{year}"
            end_date = "#{month}/#{last_day}/#{year}"
            links, cookie, bad_request = get_inner_page_links(start_date, end_date, letter, case_type)
            if bad_request 
              keeper.insert_scrape_date_track({year: year, month: month, case_type: case_type, bad_request: true})
            elsif links.count == 0
              keeper.insert_scrape_date_track({year: year, month: month, case_type: case_type, no_links: true})
            elsif links.count < 500
              flag = process_links(start_date, end_date, letter, case_type, links, cookie)
              keeper.insert_scrape_date_track({year: year, month: month, case_type: case_type, is_completed: true}) if flag
              keeper.insert_scrape_date_track({year: year, month: month, case_type: case_type, processing_error: true}) unless flag
            else
              # i.e links are more than 500
              last_day = Date.new(year, month, -1).day
              (1..last_day).each do |day| 
                # spliting over days
                next if year_month_day_array.include? [year, month, day, case_type]
                start_date = "#{month}/#{day}/#{year}"
                end_date = "#{month}/#{day}/#{year}"
                links, cookie, bad_request = get_inner_page_links(start_date, end_date, letter, case_type)
                if bad_request 
                  keeper.insert_scrape_date_track({year: year, month: month, day: day, case_type: case_type, bad_request: true})
                elsif links.count == 0
                  keeper.insert_scrape_date_track({year: year, month: month, day: day, case_type: case_type, no_links: true})
                elsif links.count < 500
                  flag = process_links(start_date, end_date, letter, case_type, links, cookie)
                  keeper.insert_scrape_date_track({year: year, month: month, day: day, case_type: case_type, is_completed: true}) if flag
                  keeper.insert_scrape_date_track({year: year, month: month, day: day, case_type: case_type, processing_error: true}) unless flag
                else
                  # i.e links are more than 500
                  ('a'..'z').each do |letter|
                    next if year_month_day_letter_array.include? [year, month, day, letter, case_type]
                    links, cookie, bad_request = get_inner_page_links(start_date, end_date, letter, case_type)
                    if bad_request 
                      keeper.insert_scrape_date_track({year: year, month: month, day: day, letter: letter, case_type: case_type, bad_request: true})
                    elsif links.count == 0
                      keeper.insert_scrape_date_track({year: year, month: month, day: day, letter: letter, case_type: case_type, no_links: true})
                    elsif links.count < 500
                      flag = process_links(start_date, end_date, letter, case_type, links, cookie)
                      keeper.insert_scrape_date_track({year: year, month: month, day: day, letter: letter, case_type: case_type, is_completed: true}) if flag
                      keeper.insert_scrape_date_track({year: year, month: month, day: day, letter: letter, case_type: case_type, processing_error: true}) unless flag
                    else
                      # need to fiund further spliting
                      keeper.insert_scrape_date_track({year: year, month: month, day: day, letter: letter, case_type: case_type, need_to_split: true})
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    logger.info "Scrape - Download Done!"
  end

  def store
    already_inserted_ids = keeper.info_case_ids
    saved_files = s3.find_files_in_s3("us_courts/#{COURT_ID}/htmls/")
    logger.info "Found #{saved_files.count} files"
    saved_files.each do |file|
      file_key = file[:key]
      file_name = file_key.split('htmls/').last.split(".html").first
      if already_inserted_ids.include? file_name
        logger.info "#{file_name} Already Processed" 
        next
      end
      logger.info "Processing File #{file_name}" 
      file_obj = s3_res.bucket("court-cases-activities").object(file_key)
      file = file_obj.get.body.read
      parsed_page = parser.parse_html(file)
      data_hash = parser.main_data_parser(parsed_page, run_id)
      if data_hash.empty?
        logger.info "Scrape - Already in DB!"
      else
        keeper.insert_data(data_hash)
        logger.info "Scrape - Inserted in DB!"
      end
      keeper.finish
      logger.info "Scrape - Store Done!"
    end
  end

  def cron
    logger.info "Cron Download Started"
    cron_download
    logger.info "Cron Store Started"
    store
    logger.info "Cron Store Finished"
  end

  private 

  attr_accessor :keeper, :s3, :scraper, :run_id, :parser, :s3_res

  def process_links(start_date, end_date, letter, case_type, links, cookie)
    processed_links = 0
    (0..2).each do |e|
      # to avoid links expiration
      links_index = process_links_sub(links, cookie)
      processed_links += links_index
      break if processed_links == links.count - 1 # processed all links 
      return false if e == 2 
      links, cookie, bad_request = get_inner_page_links(start_date, end_date, letter, case_type, processed_links)
    end
    return true
  end

  def process_links_sub(links, cookie)
    links_indx_count = links.count - 1
    links.each_with_index do |link, index|
      logger.info "Processing link .. #{link}"
      begin
        response = scraper.inner_page_request(link, cookie)
      rescue
        response, cookie = get_cookie_and_response
        response = scraper.inner_page_request(link, cookie)
      end
      if response.status == 302
        return index
      end
      parsed_page = parser.parse_html(response.body)
      case_id, pdf_links = parser.get_case_id_pdf_files(parsed_page)
      next if @already_uploaded_or_processed_ids.include? case_id
      # we can't skip it based on link as it gonna change every time
      upload_html_file_to_aws(response, cookie, case_id)
      upload_all_pdf_files_to_aws(pdf_links, cookie, case_id)
      logger.info "#{case_id} Page Saved!"
    end
    links_indx_count 
  end

  def upload_html_file_to_aws(response, cookie, case_id)
    file_name = case_id
    content = response.body
    key = "us_courts/#{COURT_ID}/htmls/#{file_name}.html"
    return unless s3.find_files_in_s3(key).empty?
    logger.info "Uplading html file of case #{key} to --> AWS"
    s3.put_file(content, key, metadata={})
  end

  def get_cookie_and_response
    response = scraper.fetch_page(MAIN_URL)
    cookie = response.headers["set-cookie"]
    [response, cookie]
  end

  def get_case_types
    response, cookie = get_cookie_and_response
    parsed_page = parser.parse_html(response.body)
    parser.get_case_type(parsed_page)
  end

  def get_inner_page_links(start_date, end_date, letter, case_type, ind = 0)
    response, cookie = get_cookie_and_response
    parsed_page = parser.parse_html(response.body)
    google_key = parser.search_google_key(parsed_page)
    capcha_text = scraper.resolve_captcha(google_key, MAIN_URL)
    response = scraper.search_request(start_date, end_date, letter, case_type, capcha_text, google_key[:token], cookie)
    return [[], cookie, true] if response.status != 200
    parsed_page = parser.parse_html(response.body)
    links = parser.get_links(parsed_page)
    logger.info "Found #{links.count} inner links"
    return [[],cookie, false] if links.count == 0
    [links[ind..-1], cookie, false] # skiping already processed links (before expiration)
  end

  def uploaded_or_inserted_ids
    already_inserted_ids = keeper.info_case_ids
    saved_ids = s3.find_files_in_s3("us_courts/#{COURT_ID}/htmls/").map{|e| e[:key].split('htmls/').last.split(".html").first}
    (already_inserted_ids + saved_ids).uniq
  end

  def upload_file_to_aws(key, pdf_link, cookie)
    return unless s3.find_files_in_s3(key).empty?
    logger.info "Uplading pdf_link to aws --> #{pdf_link}"
    begin
      response = scraper.inner_page_request(pdf_link, cookie)
    rescue
      response, cookie = get_cookie_and_response
      response = scraper.inner_page_request(pdf_link, cookie)
    end
    logger.info "Pdf file downloaded..!"
    content = response&.body
    s3.put_file(content, key, metadata={})
  end

  def upload_all_pdf_files_to_aws(pdf_links, cookie, case_id)
    pdf_links.each_with_index do |pdf_link, ind|
      file_name = ind
      key = "us_courts/#{COURT_ID}/#{case_id}/#{file_name}.pdf"
      upload_file_to_aws(key, pdf_link, cookie)
    end
  end

  def cron_download
    @already_uploaded_or_processed_ids = uploaded_or_inserted_ids
    processed_dates = keeper.get_processed_dates
    last_date = processed_dates.last + 1
    current_date = Date.today
    case_types = get_case_types
    letter = ""
    case_type = ""
    (last_date..current_date).to_a.each do |searched_date|
      next if processed_dates.include? searched_date
      formated_date = searched_date
      searched_date = searched_date.strftime("%m/%d/%Y")
      links, cookie, bad_request = get_inner_page_links(searched_date, searched_date, letter, case_type)
      if bad_request
        keeper.insert_scrape_date_track_cron({searched_date: formated_date, bad_request: true})
      elsif links.count == 0
        keeper.insert_scrape_date_track_cron({searched_date: formated_date, no_links: true, is_completed: true})
      elsif links.count < 500
        logger.info "ON DATE : #{searched_date}"
        flag = process_links(searched_date, searched_date, letter, case_type, links, cookie)
        keeper.insert_scrape_date_track_cron({searched_date: formated_date, is_completed: true}) if flag
        keeper.insert_scrape_date_track_cron({searched_date: formated_date, processing_error: true}) unless flag
      else
        logger.info "ON DATE : #{searched_date}"
        case_types.each do |case_type|
          links, cookie, bad_request = get_inner_page_links(searched_date, searched_date, letter, case_type)
          if bad_request
            keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, bad_request: true})
          elsif links.count == 0
            keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, no_links: true, case_type_completed: true})
            if case_types.last == case_type
              keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, no_links: true, case_type_completed: true, is_completed: true })
            end
          elsif links.count < 500
            logger.info "ON DATE : #{searched_date} && CASE TYPE : #{case_type}"
            flag = process_links(searched_date, searched_date, letter, case_type, links, cookie)
            keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, case_type_completed: true }) if flag
            keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, processing_error: true }) unless flag
            if case_types.last == case_type && flag
              keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, case_type_completed: true, is_completed: true })
            end
          else
            ('a'..'z').each do |letter|
              links, cookie, bad_request = get_inner_page_links(searched_date, searched_date, letter, case_type)
              if bad_request
                keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, letter: letter, bad_request: true})
              elsif links.count == 0
                keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, letter: letter, no_links: true, letter_completed: true})
                if case_types.last == case_type && letter == "z"
                  keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, letter: letter, no_links: true, case_type_completed: true, letter_completed: true, is_completed: true })
                end
              elsif links.count < 500
                logger.info "ON DATE : #{searched_date} && CASE TYPE : #{case_type} && LETTER : #{letter}"
                flag = process_links(searched_date, searched_date, letter, case_type, links, cookie)
                keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, letter: letter, letter_completed: true }) if flag
                keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, letter: letter, processing_error: true }) unless flag
                if letter == "z" && flag
                  keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, letter: letter, case_type_completed: true, letter_completed: true })
                  if case_types.last == case_type
                    keeper.insert_scrape_date_track_cron({searched_date: formated_date, case_type: case_type, letter: letter, case_type_completed: true, letter_completed: true, is_completed: true })
                  end
                end
              else
                logger.info "Need More Spliting"
              end
            end
          end
        end
      end
    end
  end
end
