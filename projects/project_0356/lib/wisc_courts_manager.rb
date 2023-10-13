require_relative 'wisc_courts_parser'
require_relative 'wisc_courts_scraper'
require_relative 'wisc_courts_keeper'

class WiscCourtsManager < Hamster::Harvester
  def initialize
    super
    @keeper    = WiscCourtsKeeper.new
    @count_aws = 0
  end

  def download
    peon.move_all_to_trash
    peon.throw_trash(30)
    scraper = WiscCourtsScraper.new(keeper)
    scraper.scrape_open_case
    Hamster.logger.info "Scraped open case: #{scraper.count_open}".green
    scraper.scrape_new_case
    keeper.status = 'scraped'
    Hamster.logger.info "Scraped new case: #{scraper.count_new}".green
  end

  def save_activities_aws
    s3         = AwsS3.new(bucket_key = :us_court)
    activities = keeper.get_file_activities
    activities.each do |activity|
      url  = activity[:file]
      body = get_body(url)
      next if body.nil?

      file_name = "wisc_case_#{activity[:court_id]}_#{activity[:case_id]}_#{Time.now.to_i.to_s}.pdf"
      aws_link  = s3.put_file(body, file_name, metadata = { url: url })
      pdfs_aws  = { court_id: activity[:court_id], case_id: activity[:case_id], aws_link: aws_link, source_link: url }
      keeper.save_pdfs_aws_info(pdfs_aws, activity[:md5_hash])
      @count_aws += 1
    end
    Hamster.logger.info "Saved activities in AWS: #{@count_aws}".green
  end

  def store
    current_id = keeper.run_id
    cases      = peon.give_list(subfolder: "#{current_id}_case")
    cases.each do |name|
      main_page = WiscCourtsParser.new(peon.give(file: name, subfolder: "#{current_id}_case"))
      main      = main_page.parse_main_page
      next if main.empty?

      keeper.save_case(main)
      name            = name.sub('.gz', '_history.gz')
      activities_page = peon.give(file: name, subfolder: "#{current_id}_case_history")
      parser          = WiscCourtsParser.new(activities_page)
      activities      = parser.get_activities
      unless activities.empty?
        keeper.save_activities(activities)
        keeper.check_date_info
      end
    end
    Hamster.logger.info "Created - #{keeper.count}, updated - #{keeper.updated}".green
    keeper.status = 'saving_activities_aws'
    save_activities_aws
    keeper.status = 'saving_info_aws'
    save_info_aws
    keeper.finish
  end

  private

  attr_reader :keeper

  def save_info_aws
    cases_courts = keeper.get_not_pdf_link
    s3           = AwsS3.new(bucket_key = :us_court)
    scraper      = WiscCourtsScraper.new(keeper)
    cases_courts.each do |case_court|
      pdf_link = case_court.last + '&printable=1&outputType=fspdf'
      pdf_page = scraper.response(pdf_link)
      next if pdf_page.status == 500

      pdf = pdf_page.body
      next unless pdf

      court_id = case_court[0]
      case_id  = case_court[1]
      md5      = MD5Hash.new(columns: %i[pdf])
      md5.generate({pdf: pdf})
      md5_hash = md5.hash
      pdf_name = "wisc_case_#{court_id}_#{case_id}_#{md5_hash}.pdf"
      aws_link = s3.put_file(pdf, pdf_name, metadata = { url: pdf_link })
      pdfs_aws = { court_id: court_id, case_id: case_id, aws_link: aws_link, source_link: pdf_link, source_type: 'info' }
      info_md5 = case_court[2]
      keeper.save_pdfs_aws_info(pdfs_aws, info_md5, model=:info)
    end
    count_aws = keeper.count_aws
    Hamster.logger.info "Saved infos in AWS: #{count_aws}".green
  end

  def get_body(url)
    scraper = WiscCourtsScraper.new(keeper)
    url.match?(%r{eFiled|document/uploaded|document/scanned}) ? scraper.get_pdf_dasher(url) : scraper.get_pdf(url)
  end
end
