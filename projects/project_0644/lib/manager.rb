# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class Manager < Hamster::Scraper

  def initialize(**params)
    super
    @keeper  = Keeper.new
    @parser  = Parser.new
    @scraper = Scraper.new
    @s3 = AwsS3.new(bucket_key = :us_court)
    @run_id = keeper.run_id.to_s
  end

  def run
    (keeper.download_status == "finish") ? store : download
  end

  def download
    dates_array = get_slice_array
    @two_captcha = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)
    decoded_captcha = solve_captcha
    response = scraper.authentication_connect(decoded_captcha.text)
    cookie_value = response.headers["set-cookie"]
    dates_array.each_with_index do |dates, ind|
      start_date = dates.first.to_s
      end_date   = dates.last.to_s
      outer_folder = start_date.gsub('-', '_')
      already_downloaded_files = peon.list(subfolder: "#{run_id}/#{outer_folder}") rescue []
      main_page_request =  scraper.main_page(start_date, end_date, cookie_value)
      inner_links = parser.find_ids(main_page_request.body)
      inner_links.each do |link|
        folder = link.split('/').last
        next if already_downloaded_files.include? folder

        responses = scraper.inner_pages(link)
        save_responses(outer_folder, responses, link)
        download_activities_pdfs(responses.last, folder, cookie_value)
      end
    end
    keeper.finish_download
    store if (keeper.download_status == "finish")
  end

  def store
    dates_folders = peon.list(subfolder: run_id)
    dates_folders.each do |date_folder|
      cases_folders = peon.list(subfolder: "#{run_id}/#{date_folder}") rescue []
      cases_folders.each do |case_folder|
        inner_folder = "#{run_id}/#{date_folder}/#{case_folder}"
        info_data = peon.give(file: 'info.gz', subfolder:  inner_folder)
        events_data = peon.give(file: 'events.gz', subfolder:  inner_folder)
        parties_data = peon.give(file: 'parties.gz', subfolder:  inner_folder)
        case_info, activites_array, parties_array = parser.parse(info_data, events_data, parties_data, case_folder, run_id)
        aws_hash_array, relations_hash_array, activites_array = create_aws_hashes(case_info, case_folder, activites_array)
        activites_array.each { |e| e[:activity_pdf] = nil unless e[:activity_pdf].nil? or e[:activity_pdf].length > 15 }
        keeper.insert_info(case_info) unless case_info.nil?
        keeper.insert_activity(activites_array) unless activites_array.empty?
        keeper.insert_party(parties_array) unless parties_array.empty?
        keeper.insert_pdf_aws_hash(aws_hash_array) unless aws_hash_array.empty?
        keeper.insert_pdf_activity_relation(relations_hash_array) unless relations_hash_array.empty?
      end
    end
    if (keeper.download_status == "finish")
      keeper.mark_delete
      keeper.finish
    end
  end

  private

  def solve_captcha(retries = 5)
    options = {
      pageurl: "https://portal.kern.courts.ca.gov/case-search/filed-date",
      googlekey: "6LeMeBIaAAAAAFOTq5ruZvCfBYOJehyl68tnQr2D"
    }
    begin
      two_captcha.decode_recaptcha_v2!(options)
    rescue Exception => e
      Hamster.report(to: 'U04N1USUK1S', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      raise if retries <= 1
      solve_captcha(retries - 1)
    end
  end

  def create_aws_hashes(case_info, case_folder, activites_array)
    aws_hash_array = []
    relations_hash_array = []    
    pdf_files = peon.give_list(subfolder: "pdfs/#{case_folder}/pdfs") rescue []
    pdf_files.each do |pdf|
      json_content =  peon.give(file: pdf, subfolder: "pdfs/#{case_folder}/json")
      pdf_link = parser.get_pdf_url(json_content)
      aws_hash = parser.pdf_on_aws(case_info, pdf.gsub('.gz', ''))
      pdf_content = peon.give(file: pdf, subfolder: "pdfs/#{case_folder}/pdfs")
      aws_hash_array << aws_upload(aws_hash, pdf_content)
      pdf_m5d_hash = aws_hash[:md5_hash]
      activity = activites_array.select { |e| e[:activity_pdf] == pdf.gsub('.gz', '') }[0]
      activity_m5d_hash = activity[:md5_hash]
      activity[:activity_pdf] = pdf_link
      relations_hash_array << parser.activity_relation_request(pdf_m5d_hash, activity_m5d_hash)
    end
    [aws_hash_array, relations_hash_array, activites_array]
  end

  def upload_file_to_aws(aws_data, pdf)
    aws_url = "https://court-cases-activities.s3.amazonaws.com/"
    return aws_url + aws_data[:aws_link] unless @s3.find_files_in_s3(aws_data[:aws_link]).empty?
    key = aws_data[:aws_link]
    @s3.put_file(pdf, key, metadata={})
  end

  def aws_upload(pdf_hash, pdf)
    pdf_hash[:aws_link] = upload_file_to_aws(pdf_hash, pdf)
    pdf_hash
  end

  def download_activities_pdfs(response, outer_folder, cookie_value)
    ids = parser.find_pdfs_ids(response.body)
    already_downloaded_pdfs = peon.list(subfolder: "pdfs/#{outer_folder}/pdfs") rescue []
    ids.each do |id|
      next if already_downloaded_pdfs.include? id

      url = "https://nimbus.kern.courts.ca.gov/case-documents/#{id}"
      response = scraper.activity_pdf_request(url, cookie_value)
      url = parser.get_pdf_url(response.body)
      next if url.nil?

      save_file("pdfs/#{outer_folder}/json", response.body, id)
      response = scraper.activity_pdf_request(url, cookie_value)
      next if response.nil?

      save_file("pdfs/#{outer_folder}/pdfs", response.body, id)
    end
  end

  def get_slice_array
    latest_folder = peon.list(subfolder: run_id).map { |e| e.gsub('_', '-').to_date}.max rescue Date.parse('01-01-2016')
    ((latest_folder)..(Date.today)).map(&:to_date).reverse.each_slice(7)
  end

  def save_responses(outer_folder, responses, link)
    folder = link.split('/').last
    names = ['info', 'parties', 'events']
    responses.each_with_index do |page, index|
      file_name = names[index]
      save_file("#{run_id}/#{outer_folder}/#{folder}", page.body, file_name)
    end
  end

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: "#{sub_folder}")
  end

  attr_accessor :keeper, :parser, :scraper, :run_id, :two_captcha
end
