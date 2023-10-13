# frozen_string_literal: true

require_relative 'car_scraper'
require_relative 'car_keeper'
require_relative 'car_parser'
require_relative '../models/us_courts_ar_model'

URL = 'https://caseinfo.arcourts.gov/cconnect/PROD/public/'
START_YEAR = 2018
CONNECTION_ERROR_CLASSES = [ActiveRecord::ConnectionNotEstablished,
                            Mysql2::Error::ConnectionError,
                            ActiveRecord::StatementInvalid,
                            ActiveRecord::LockWaitTimeout]

class ARSaacCaseManager < Hamster::Harvester
  def initialize(**options)
    super
    @scraper = Scraper.new

    @court_id = options[:court_id] || 304
    year      = options[:year]     || Date.today().year
    work      = options[:work]     || 's'
    update    = options[:update]   || 0
    # p work
    run_id_class = safe_operation(ARCaseRuns) {|model| RunId.new(model)}
    @run_id = run_id_class.run_id
    @peon = Peon.new("#{storehouse}#{@court_id}/")

    gathering(year, update) if work=='g'
    store(year) if work=='s'
    safe_operation(ARCaseRuns) { run_id_class.finish }
  end

  def gathering(year, update = 0)
    page = 0
    # file = "last_page"
    # if "#{file}.gz".in? peon.give_list() and update == 0
    #   page, = @peon.give(file:file).split(':').map { |i| i.to_i }
    # end
    parse = Parser.new(court_id=@court_id)

    court = COURTS[@court_id]
    logger.info("#{STARS}\nCOURT = '#{court}'")

    last_month = Date.today.month

    start_year = update.zero? ? Date.today.year.pred : START_YEAR
    until year < start_year
      (1..last_month).reverse_each do |month|
        logger.info("Month: #{month}, Year: #{year}")
        begin_str = "#{month}/01/#{year}"
        begin_date = Date.strptime(begin_str, "%m/%d/%Y")
        end_date = begin_date.next_month - 1
        end_str = begin_str.sub('/01/', "/#{end_date.day}/")

        url = "#{URL}ck_public_qry_doct.cp_dktrpt_new_case_report?backto=C&case_id=&begin_date=#{begin_str}&end_date=#{end_str}&county_code=ALL&cort_code=ALL&locn_code=#{court}&case_type=ALL&docket_code="
        index_page = @scraper.get_source(url) if update.zero?

        cases_on_page = update.zero? ? parse.index_page(index_page) : cases_to_update(year, month)
        logger.debug("\n#{cases_on_page}")
        #filenames = @peon.give_list(subfolder: year.to_s)
        #case_ids = filenames.map { |row| row.split('.')[0] }
        case_ids = cases_on_page.map { |row| row[:case_id]}
        existing_case_ids = existing_cases(case_ids)
        existing_md5_hash = existing_md5_hash_cases(case_ids)
        cases_on_page.each do |one_case|
          next if one_case[:case_id].in?(existing_case_ids) && (update != 1)
          page_url = "#{URL}ck_public_qry_doct.cp_dktrpt_docket_report?backto=C&case_id=#{one_case[:case_id]}&citation_no=&begin_date=&end_date="
          # ============= 5 times to avoid bad getting of next page ==========
          html_case_page = nil
          1.upto(5) do |i|
            html_case_page = @scraper.get_source(page_url)
            break if corresponding?(html_case_page, one_case[:case_id])
            Hamster.report to: OLEKSII_KUTS, message: "354_car_scraper. Case: #{one_case[:case_id]}, try ##{i} failed."
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
      end
      Hamster.report to: OLEKSII_KUTS, message: "354_ar_saac_scraper. court_id = #{@court_id}. Year #{year} with update_status '#{update.eql?(1)}' complete"
      last_month = 12
      year = year -1
    end
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
    key_start = "us_courts_expansion_#{@court_id}_#{the_case[:info][:case_id]}_"
    existed_pdfs_links = get_pdf_md5_hash(the_case[:info][:case_id])

    md5_activities = MD5Hash.new(:columns => %w(court_id case_id activity_date activity_type activity_desc file data_source_url))
    the_case[:activities].each_index do |i|
      md5_hash_activity = md5_activities.generate(the_case[:activities][i])
      the_case[:activities][i][:md5_hash] = md5_hash_activity
      the_case[:activities][i][:run_id] = run_id
      the_case[:activities][i][:touched_run_id] = run_id

      url_file = the_case[:activities][i][:file]
      if !url_file.nil?
        next if md5_hash_activity.in?(existed_pdfs_links)
        url_file = url_file.gsub('ck_image.present', 'CK_Image.Present2')
        url_pdf_on_aws = @scraper.save_to_aws(url_file, key_start)
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
        the_case[:activities][i][:file] = url_pdf_on_aws
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

  def corresponding?(html_page, case_id)
    logger.debug ("#{STARS}\n#{case_id}#{STARS}")
    html_page.include?(case_id)
  end
end
