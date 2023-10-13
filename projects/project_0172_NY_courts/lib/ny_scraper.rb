# frozen_string_literal: true

class Scraper < Hamster::Scraper

  SEARCH_URL = 'https://iapps.courts.state.ny.us/nyscef/CaseSearch?TAB=courtDateRange'
  CASE_DETAILS = 'https://iapps.courts.state.ny.us/nyscef/CaseDetails?docketId='
  CASE_DOCUMENTS = 'https://iapps.courts.state.ny.us/nyscef/DocumentList?docketId='

  STATUS_CLOSED=['Disposed', 'Disposed-Consolidated Into', 'Disposed-Court Date/Application Pending', 'Disposed, Motion Pending', 'Stayed', 'Stayed-Court Date/Application Pending']

  def initialize(**args)
    super
    # run_id_class = RunId.new()
    # @run_id = run_id_class.run_id
    @scrape_dev_name = 'Maxim G'
    @captcha_number = 0
    @wo_pdf = args[:wo_pdf].nil? ? false : true
    #@two_captcha = Hamster::CaptchaSolver.new()
    @two_captcha = Hamster::CaptchaAdapter.new(:two_captcha_com)
    logger.info @two_captcha.balance
    @s3 = AwsS3.new(bucket_key = :us_court)
    @instance = args[:instance]

    if args[:store]
      begin
        gathering(0)
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
        logger.error 'BAD date!!! Type YYYY-MM-DD'
        first_scrape_date = Date.today()
      end

      begin
        if args[:update]==3
          gathering(3,first_scrape_date, court_number)
          get_from_old_urls('new')
        else
          gathering(1,first_scrape_date, court_number )
        end
      rescue Exception => e
        rescue_method(e)
      end

    elsif args[:old_amount]
      get_from_old_urls(args[:old_amount])
    # elsif args[:check]==1
    #   download_pdf
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
    logger.error mess
    @hammer.close if !@hammer.nil?
    #@hammer_case.close if !@hammer_case.nil?
    exit 0
  end

  def gathering(update=0, first_permanent_scrape_date=nil, first_court_number=nil)
    datetime_of_cycle = DateTime.now()
    peon = Peon.new(storehouse)
    run_id_model = RunId.new(NYCaseRuns)
    @run_id = run_id_model.last_id
    case update
    when 1
      final_scrape_date = Date.new(2022,1,1)
    when 3
      final_scrape_date = Date.today - 15
    else
      final_scrape_date = Date.new(2022,1,1)
    end

    last_place_file = 'last_place'

    first_permanent_scrape_date = Date.today()-1 if first_permanent_scrape_date.nil?

    if "#{last_place_file}.gz".in? peon.give_list() and update == 0
      last_scraping_date, first_court_number, = peon.give(file:last_place_file).split('|')
      first_permanent_scrape_date = Date.parse(last_scraping_date)
    end


    COURTS.each_key do |court_number|
      if !first_court_number.nil?
        if court_number.to_s != first_court_number.to_s
          next
        elsif court_number.to_s == first_court_number.to_s
          first_court_number=nil
        end
      end
      court_id = COURTS[court_number][:id]

      unless @instance.nil?
        if @instance!=0
          @instance-=1
          exit 0 if @instance<0 or @instance>70
          next
        end
      end

      logger.debug "Court: #{court_number} / #{court_id}"
      @hammer.close if !@hammer.nil?
      @hammer = Dasher.new(:using=>:hammer, pc:1, save_path: "#{storehouse}trash/#{court_id}/")

      scrape_date = first_permanent_scrape_date
      while_scrape_date = scrape_date - 6
      final_scrape_date = while_scrape_date if final_scrape_date > while_scrape_date
      if update==3
        last_date_in_db = last_date_in_index_table(court_id)
        final_scrape_date = last_date_in_db if !last_date_in_db.nil? && last_date_in_db>final_scrape_date
        while_scrape_date = final_scrape_date if final_scrape_date > while_scrape_date
      end

      existing_dates = []

      while while_scrape_date >= final_scrape_date
        error_counter = 0
        while_scrape_date = scrape_date - 6
        logger.debug "While: #{while_scrape_date} and final: #{final_scrape_date} and scrape: #{scrape_date}"
        counter_browser = 0
        hash_cases = {}
        while scrape_date>while_scrape_date

          if !existing_dates.empty? && scrape_date>existing_dates[0] && update!=3
            scrape_date = existing_dates[0]
            while_scrape_date = while_scrape_date - 4
          end

          if scrape_date.in?(existing_dates)
            while_scrape_date = while_scrape_date - 1
            scrape_date = scrape_date - 1
            redo
          end

          if @captcha_number>1000
            hours = (DateTime.now() - datetime_of_cycle)*24
            mess = "Captcha:#{@captcha_number}, for #{hours} hours, Balance: #{@two_captcha.balance}"
            Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)

            @browser.quit if !@browser.nil?
            #@hammer_case.close if !@hammer_case.nil?
            exit 0
          end


          if counter_browser>10
            @hammer.connect
            counter_browser = 0
          end
          begin
            @hammer.get(SEARCH_URL)
            sleep 1.2
            @browser = @hammer.connection
          rescue => e
            logger.error(e)
            @hammer.connect
            error_counter +=1
            sleep(error_counter**2*100)
            return if error_counter>4
            redo
          end
            sleep 3.5

          if captcha_page_html(@browser.body)
            begin
              handle_captcha_in_browser
            rescue Exception =>e
              mess = "Captcha_number: #{@captcha_number}|#{@two_captcha.balance} \nError: #{e}"
              Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
              logger.error mess
              @hammer.close if !@browser.nil?
              #@hammer_case.close if !@hammer_case.nil?
              redo
            end
          elsif !general_page_found(@browser.body)
            @hammer.close
            @hammer.connect if !@browser.nil?
            @browser=@hammer.connection
            redo
          end

          new_cases = get_list_cases_from_browser(scrape_date, court_number)
          save_general_to_index(new_cases, court_id, scrape_date)
          hash_cases[scrape_date] = new_cases
          scrape_date = scrape_date - 1
          counter_browser +=1
        end
        reconnect_db
      end
    end
    @hammer.close
    peon.move(file: last_place_file) if "#{last_place_file}.gz".in? peon.give_list()
  end

  def save_pdfs(court_id, case_id, activities, data_source_url)
    url_on_pdfs = activities.map{|act| act[:activity_pdf] if !act[:activity_pdf].nil?}
    existing_urls = get_existing_saved_pdfs(case_id, url_on_pdfs)
    key_start = "us_courts/#{court_id}/#{case_id}/"
    relations_activity_pdf = []
    path_to_pdf_folder = "#{storehouse}trash/#{court_id}/*.pdf"
    counter_to_break = 0
    activities.each do |act|
      pdf_link = act[:activity_pdf]
      next if pdf_link.nil?
      if existing_urls.keys().include?(pdf_link)
        relations_activity_pdf.push({
                                      case_activities_md5: act[:md5_hash],
                                      case_pdf_on_aws_md5: existing_urls[pdf_link]
                                    }
        )
        next
      end
      begin
        @hammer.get(pdf_link)
      rescue => e
        log("Error with getting pdf: #{pdf_link}")
        clear_folder(path_to_pdf_folder)
        return relations_activity_pdf if counter_to_break>3
        counter_to_break +=1
        next
      end

      aws_link = ''
      Dir[path_to_pdf_folder].each do |pdf_file|
        key = key_start + pdf_file.split('/')[-1]
        File.open(pdf_file, 'rb') do |file|
          aws_link = @s3.put_file(file, key, metadata=
              {
                url: pdf_link,
                case_id: case_id,
                court_id: court_id.to_s
              })
        end
      end
      clear_folder(path_to_pdf_folder)

      pdf_on_aws = {
        case_id: case_id,
        court_id: court_id,
        source_type: 'activity',
        source_link: pdf_link,
        aws_link: aws_link,
        data_source_url: data_source_url
      }
      md5_info = MD5Hash.new(columns: %w[court_id case_id source_type source_link data_source_url])
      md5_hash_string = md5_info.generate(pdf_on_aws)
      pdf_on_aws[:md5_hash] = md5_hash_string
      insert_pdf(pdf_on_aws)

      relations_activity_pdf.push({
          case_activities_md5: act[:md5_hash],
          case_pdf_on_aws_md5: md5_hash_string
                                  }
      )
      insert_relations(relations_activity_pdf[-1])
    end

    clear_folder(path_to_pdf_folder)
    relations_activity_pdf
  end

  def clear_folder(path_to_folder)
    Dir[path_to_folder].each do |filename|
      File.delete(filename) if File.exist?(filename)
    end
  end

  def captcha_page?
    @agent.current_page.form_with(name: 'captcha_form') or @agent.current_page.css('noscript')[0].content.split(' ')[0]=='Please'
  end

  def get_list_cases_from_browser(scrape_date=(Date.today()-1), court_number=25)
    filed_date = "#{scrape_date.month.to_s.rjust(2, '0')}/#{scrape_date.day.to_s.rjust(2, '0')}/#{scrape_date.year}"
    court_name = COURTS[court_number][:court_name]
    waiter = 0
    begin
      @browser.at_css("select[id='selCountyCourt']").focus.click.type(court_name.split(' ')[0]).click
      sleep 0.2
      @browser.at_css("input[id='txtFilingDate']").focus.type(filed_date)
      sleep 0.2
      @browser.at_css("input[class='BTN_Green']").focus.click
      sleep 2.5
      @page_with_cases = @browser.body.dup
      list_cases = parse_list_case_url(@page_with_cases)
    rescue Exception => e
      logger.error e
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
    js_script = "document.getElementById('g-recaptcha-response').innerHTML='#{decoded_captcha.text}';"
    @browser.execute(js_script)
    @browser.execute("onCaptchaSolved()")
    sleep 7
    @browser.go_to(SEARCH_URL)
  end


  def get_from_old_urls(options=2)
    limit = 1000
    last_place_file = 'last_page_amount'
    last_page = 0
    # last_court_id = nil
    # if "#{last_place_file}.gz".in? peon.give_list()
    #   last_page, last_court_id, = peon.give(file:last_place_file).split(':').map { |i| i.to_i }
    # end
    run_id_model = RunId.new(NYCaseRuns)
    run_id = run_id_model.last_id

    COURTS.each_value do |court|
      court_id = court[:id]
      # if !last_court_id.nil?
      #   if court_id!=last_court_id
      #     next
      #   elsif court_id==last_court_id
      #     last_court_id=nil
      #   end
      # end

      page = last_page
      last_page = 0
      @hammer = Dasher.new(:using=>:hammer, pc:1, save_path: "#{storehouse}trash/#{court_id}/")
      logger.info "Court_id: #{court_id}"
      loop do
        logger.info "Page: #{page}"
        offset = page*limit
        case_links = {}
        if options=='2'
          NYCaseInfo.where(court_id:court_id).where(deleted:1).where("DATE(case_filed_date) > ?", Date.new(2016,1,1)).order(case_filed_date: :desc).limit(limit).offset(offset).map { |row| case_links[row.data_source_url] = row.case_filed_date }
        elsif options=='3'
          NYCaseInfo.where(court_id:court_id).where(deleted:0).where(disposition_or_status:'Waiting for Index Number').order(:case_filed_date).limit(limit).offset(offset).map { |row| case_links[row.data_source_url] = row.case_filed_date }
        elsif options=='upd'
          NYCaseInfo.where(court_id:court_id).where(deleted:0).where.not(status_as_of_date:STATUS_CLOSED).where("updated_at<'#{Date.today()-25}'").limit(limit).offset(offset).map { |row| case_links[row.data_source_url] = row.case_filed_date }
        elsif options=='new'
          cases_not_downloaded = NYCaseIndex.where(court_id:court_id).where(done:0).limit(limit).offset(offset).all
          cases_not_downloaded.map { |row| case_links[row.data_source_url] = row.case_filed_date }
        else
          USCaseInfo.where(court_id:court_id).where("DATE(case_filed_date) > ?", Date.new(2016,1,1)).order(case_filed_date: :desc).limit(limit).offset(offset).map { |row| case_links[row.data_source_url] = row.case_filed_date }
        end

        if !['3', 'upd'].include?(options)
          existing_links = existing_cases_info(case_links.keys)
        else
          existing_links = []
        end

        @hammer.connect
        case_links.each do |link, case_filed_date|
          logger.info link
          next if link.in?(existing_links)
          counter = 0
          logger.info "counter #{counter}"
          begin
            page_detail = @hammer.get(link)

            scrape_date = nil

            docket_id = link.split('docketId=')[-1].split('&')[0]
            case_detail = CaseDetail.new(page_detail, case_filed_date, @scrape_dev_name, link, docket_id, court_id)
            case_id  = case_detail.case_id
            court_id = case_detail.court_id
            logger.debug "court_id: #{court_id}, case_id: #{case_id}"
            sleep 0.5

            document_link = CASE_DOCUMENTS+docket_id
            page_document = @hammer.get(document_link)
            document_list = DocumentList.new(page_document, @scrape_dev_name, document_link, docket_id)
            activities = document_list.case_activities

            relations =
              if case_id!=docket_id and !@wo_pdf
                save_pdfs(court_id, case_id, activities, document_link)
              else
                []
              end

          rescue => e
            logger.error e
            @hammer.close
            counter+=1
            next if counter>3
            retry
          end
          mark_deleted_by_case_id(docket_id) if options=='3' and case_id!=docket_id
          put_all_in_db(case_detail, activities, relations, run_id)
          sleep 0.5
        end
        peon.put(content: "#{page}:#{court_id}:", file: last_place_file)
        page=page+1
        if options=='new'
          cases_not_downloaded.update_all(done:1)
          page=0
        end

        @hammer.close
        break if case_links.length<limit
        reconnect_db
      end
    end
  end


  def save_general_to_index(cases, court_id, case_filled_date)
    cases_index = []
    logger.info "saving #{cases.length} cases"
    cases.each do |case_id, docket_id|
      cases_index<< {
        court_id: court_id,
        case_id: case_id,
        docket_id: docket_id,
        case_filed_date: case_filled_date,
        data_source_url: CASE_DETAILS+docket_id,
      }
    end

    insert_cases_to_index(cases_index)

  end

end