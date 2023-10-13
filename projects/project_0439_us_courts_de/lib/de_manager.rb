# frozen_string_literal: true

require_relative 'de_scraper'
require_relative 'de_keeper'
require_relative 'de_parser'
require_relative '../models/us_courts_de_model'

URL = "https://courtconnect.courts.delaware.gov/cc/cconnect/"
START_YEAR = 2018
CLOSED_STATUS = [ 'EXECUTION - EXECUTION',
                  'SATISFIED - SATISFIED',
                  'JUDGMENT - JUDGMENT',
                  'CLOSED - CLOSED']
ACTIVE_STATUS = [ 'ACTIVE - ACTIVE',
                  'NEW - NEW']
CONNECTION_ERROR_CLASSES = [ActiveRecord::ConnectionNotEstablished,
                            Mysql2::Error::ConnectionError,
                            ActiveRecord::StatementInvalid,
                            ActiveRecord::LockWaitTimeout]

class DECaseManager < Hamster::Harvester
  def initialize(**options)
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
    @scraper = Scraper.new

    @court_id = options[:court_id] || 71
    year      = options[:year]     || Date.today.year
    work      = options[:work]     || 's'
    update    = options[:update].nil? ? 0 : 1
    period    = options[:period]   || ''
    status    = options[:status]   || 'a'
    @intervals = scraping_intervals(update, period)
    run_id_class = safe_operation(DECaseRuns) {|model| RunId.new(model)}
    @run_id = run_id_class.run_id
    @peon = Peon.new(storehouse)

    answer = gathering(update, status)                if work == 'g'
    store(year)                                       if work == 's'
    safe_operation(DECaseRuns) {run_id_class.finish}  if answer == 1
  end

  def interval_to_s(begin_date, end_date)
    {begin_str: begin_date.strftime("%d-%b-%Y"),
       end_str: end_date.strftime("%d-%b-%Y")}
  end

  def year_intervals(year, month = 12)
    begin_date = Date.new(year, month, 1)
    12.times.map do |n|
      interval_to_s(begin_date.prev_month(n), begin_date.prev_month(n).end_of_month)
    end
  end

  def month_intervals_recurrent(start_date, end_date)
    return [] if start_date > end_date
    [interval_to_s([start_date, end_date.beginning_of_month].max, end_date)] +
    month_intervals_recurrent(start_date, end_date.prev_month.end_of_month)
  end

  def scraping_intervals(update, period)
    intervals = []
    now = Date.today
    if update == 0
      intervals += month_intervals_recurrent(now.prev_month(3), now)
    elsif update == 1
      intervals += year_intervals(now.year, now.month) if (period == 'm' || period == 'w' || period.empty?)
      (START_YEAR..now.year.pred).reverse_each {|year| intervals += year_intervals(year)} if (period == 'q' || period == 'w' || period.empty?)
    end
    intervals.uniq
  end

  def gathering(update = 0, status = 'a')
    page = nil
    # file = "last_page"
    # if "#{file}.gz".in? peon.give_list() and update == 0 and year.nil?
    #   page, last_letter,year,month = @peon.give(file:file).split(':').map { |i| i }
    # end
    parse = Parser.new(court_id=@court_id)

    @intervals.each do |interval|
      logger.info(interval)
      year = Date.strptime(interval[:begin_str], "%d-%b-%Y").year

      (('1'..'9').to_a + ('a'..'z').to_a).each do |letter|
        logger.debug(letter)
        # next if letter!=last_letter and !last_letter.nil? #and update==0
        # last_letter=nil
        page = page.nil? ? 1 : page.to_i
        loop do
          url = "#{URL}ck_public_qry_cpty.cp_personcase_srch_details?backto=P&soundex_ind=&partial_ind=checked&last_name=#{letter}&first_name=&middle_name=&begin_date=#{interval[:begin_str]}&end_date=#{interval[:end_str]}&case_type=ALL&id_code=&PageNo=#{page}"
          index_page = @scraper.get_source(url) if update.zero?

          cases_on_page = update.zero? ? parse.index_page(index_page) : cases_to_update(interval, letter)
          logger.debug("\n#{cases_on_page}")
          number_of_cases_on_page = cases_on_page.size
          cases_on_page.select! {|el| el[:case_status].in?(CLOSED_STATUS)} if status == 'c'
          cases_on_page.reject! {|el| el[:case_status].in?(CLOSED_STATUS)} if status == 'o'
          cases_on_page.select! {|el| el[:case_status].in?(ACTIVE_STATUS)} if status == 'an'
          logger.debug("\n#{cases_on_page}")

          #filenames = @peon.give_list(subfolder: year.to_s)
          #case_ids = filenames.map { |row| row.split('.')[0] }
          case_ids = cases_on_page.map { |row| row[:case_id]}
          existing_case_ids = existing_cases(case_ids)
          existing_md5_hash = existing_md5_hash_cases(case_ids)
          cases_on_page.each do |one_case|
            next if existing_case_ids.include?(one_case[:case_id]) && update!=1
            page_url = "#{URL}ck_public_qry_doct.cp_dktrpt_docket_report?backto=P&case_id=#{one_case[:case_id]}&begin_date=&end_date="
            # ============= 5 times to avoid bad getting of next page ==========
            html_case_page = nil
            1.upto(5) do |i|
              html_case_page = @scraper.get_source(page_url)
              break if corresponding?(html_case_page, one_case[:case_id])
              Hamster.report to: OLEKSII_KUTS, message: "439_de_scraper. Case: #{one_case[:case_id]}, try ##{i} failed."
            end
            next if !corresponding?(html_case_page, one_case[:case_id])
            # ============= 5 times to avoid bad getting of next page ==========
            begin
              @peon.put(content: html_case_page, file: one_case[:case_id].gsub(' ',''), subfolder: year.to_s)
            rescue => e
              [STARS,  e].each {|line| logger.error(line)}
            end
            # parse.case_page(html_case_page, one_case[:case_id])
            the_case = parse.case_page(html_case_page, one_case[:case_id])
            the_case = add_additional(the_case)
            logger.debug ("#{STARS}\n#{the_case}")

            mark_deleted(the_case[:info][:case_id]) if update.eql?(1)
            existing_md5_hash.include?(the_case[:info][:md5_hash]) ? put_all_in_db(the_case, @run_id) : put_all_in_db(the_case)
          end
          page += 1
          break if number_of_cases_on_page<20
          break unless update.zero?
          # peon.put(content: "#{page}:#{letter}:#{year}:#{month}", file: file)
        end
        page = nil
      end
      Hamster.report to: OLEKSII_KUTS, message: "439_de_scraper. Interval #{interval} with status '#{status}' complete"
    end
    1
  end

  def store(year)
    parse = Parser.new(court_id=@court_id)
    filenames = @peon.give_list(subfolder: year.to_s)
    case_ids = filenames.map { |row| row.split('.')[0] }
    existing_case_ids = existing_cases(case_ids)
    filenames.each do |filename|
      case_id = filename.split('.')[0]
      next if case_id.in?(existing_case_ids)
      html_case_page = @peon.give(file: filename, subfolder: year.to_s)
      the_case = parse.case_page(html_case_page, case_id)
      the_case = add_additional(the_case)
      put_all_in_db(the_case)
    end
  end

  def monthes
    %W(#{} jan feb mar apr may jun jul aug sep oct nov dec)
    # ['','jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
  end

  def add_additional(the_case)
    run_id = @run_id
    md5_info = MD5Hash.new(table: :info)
    the_case[:info][:md5_hash] = md5_info.generate(the_case[:info])
    the_case[:info][:run_id] = run_id
    the_case[:info][:touched_run_id] = run_id

    md5_party = MD5Hash.new(table: :party)
    the_case[:party].each_index do |i|
      the_case[:party][i][:md5_hash] = md5_party.generate(the_case[:party][i])
      the_case[:party][i][:run_id] = run_id
      the_case[:party][i][:touched_run_id] = run_id
    end

    pdfs_on_aws = []
    relations_activity_pdf = []
    key_start = "us_courts_#{@court_id}_#{the_case[:info][:case_id]}_"
    existed_pdfs_links = get_pdf_md5_hash(the_case[:info][:case_id])

    md5_activities = MD5Hash.new(:columns => %w(court_id case_id activity_date activity_decs activity_type activity_pdf data_source_url))
    the_case[:activities].each_index do |i|
      md5_hash_activity = md5_activities.generate(the_case[:activities][i])
      the_case[:activities][i][:md5_hash] = md5_hash_activity
      the_case[:activities][i][:run_id] = run_id
      the_case[:activities][i][:touched_run_id] = run_id

      url_file = the_case[:activities][i][:activity_pdf]
      if !url_file.nil?
        next if md5_hash_activity.in?(existed_pdfs_links)
        url_file = url_file.gsub('ck_image.present', 'CK_Image.Present2')
        url_pdf_on_aws = save_to_aws(url_file, key_start)
        pdfs_on_aws.push({
                           court_id: @court_id,
                           case_id: the_case[:info][:case_id],
                           source_type: 'activities',
                           aws_link: url_pdf_on_aws,
                           source_link: url_file,
                           data_source_url: the_case[:activities][i][:data_source_url],
                           run_id: run_id,
                           touched_run_id: run_id,
                         })
        the_case[:activities][i][:activity_pdf] = url_pdf_on_aws
        md5_pdf_on_aws = MD5Hash.new(table: :pdfs_on_aws)
        pdfs_on_aws[-1][:md5_hash] = md5_pdf_on_aws.generate(pdfs_on_aws[-1])
        relations_activity_pdf.push({
                                      court_id: @court_id,
                                      case_id: the_case[:info][:case_id],
                                      case_pdf_on_aws_md5:pdfs_on_aws[-1][:md5_hash],
                                      case_activities_md5: the_case[:activities][i][:md5_hash]
                                    })
      end
    end
    the_case[:pdfs_on_aws] = pdfs_on_aws
    the_case[:relations_activity_pdf] = relations_activity_pdf
    the_case
  end

  # def save_to_aws(url_file, key_start)
  #     cobble = Dasher.new(:using=>:cobble)
  #     body = cobble.get(url_file)
  #     key = key_start + Time.now.to_i.to_s + '.pdf'
  #     @s3.put_file(body, key, metadata={url: url_file})
  # end

  def corresponding?(html_page, case_id)
    logger.debug ("#{STARS}\n#{case_id}#{STARS}")
    res = html_page.include?(case_id)
  end
end
