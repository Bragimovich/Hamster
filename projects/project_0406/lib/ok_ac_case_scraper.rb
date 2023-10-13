# frozen_string_literal: true

require_relative '../models/ok_ac_case_runs'
require_relative '../models/ok_ac_case_info'
require_relative '../models/ok_ac_case_pdfs_on_aws'
require 'pry'

def make_md5(hash, keys)
  values_str = ''
  keys.each { |key| values_str += (hash[key].nil? ? 'nil' : hash[key].to_s) }
  Digest::MD5.hexdigest values_str
end

class OkAcCaseScraper < Hamster::Scraper

  SOURCE = 'https://www.oscn.net/dockets/'
  IDX_SUB_FOLDER = 'ac_indexes/'
  CASES_SUB_FOLDER = 'ac_cases'
  COURT_ID = '460'

  def initialize(*_)
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @court = nil
    @year = 2016
    @run_id = nil
  end

  def start
    Hamster.report(to: 'Alim Lumanov', message: "Project #406 download started", use: :both)

    download
    p 'download finished'

    Hamster.report(to: 'Alim Lumanov', message: "Project #406 download finished", use: :both)
  rescue StandardError => e
    p 'inside outer rescue'
    p e
    Hamster.report(to: 'Alim Lumanov', message: "Project #406 --download->start: Error - \n#{e}", use: :both)
  end

  private

  def download
    mark_as_started

    closed_cases = list_closed_cases(COURT_ID)
    current_year = Time.now.year
    (@year..current_year).each do |year|
      cases_folder = CASES_SUB_FOLDER + "_#{year}/"
      ('A'..'Z').each do |letter|
        page_link = SOURCE + "Results.aspx?db=appellate&number=#{letter}%-#{year}-%&lname=&fname=&mname=&DoBMin=&DoBMax=&partytype=&apct=&dcct=&FiledDateL=&FiledDateH=&ClosedDateL=&ClosedDateH=&iLC=&iLCType=&iYear=&iNumber=&citation="
        page = connect_to(page_link, proxy_filter: @filter, ssl_verify: false)&.body
        cases = list_index_cases(page)
        next if cases.empty?
        if cases.size < 500
          save_file(page, "#{year}_#{letter}", IDX_SUB_FOLDER)
          save_cases(cases, closed_cases, cases_folder)
        else
          ('1'..'9').each do |digit|
            page_link = SOURCE + "Results.aspx?db=appellate&number=#{letter}%-#{year}-#{digit}%&lname=&fname=&mname=&DoBMin=&DoBMax=&partytype=&apct=&dcct=&FiledDateL=&FiledDateH=&ClosedDateL=&ClosedDateH=&iLC=&iLCType=&iYear=&iNumber=&citation="
            page = connect_to(page_link, proxy_filter: @filter, ssl_verify: false)&.body
            cases = list_index_cases(page)
            next if cases.empty?
            save_file(page, "#{year}_#{letter}_#{digit}", IDX_SUB_FOLDER)
            save_cases(cases, closed_cases, cases_folder)
          rescue StandardError => e
            p e
            p e.full_message
            Hamster.report(to: 'Alim Lumanov', message: "Project #406 --download->index: Error - \n#{e}", use: :both)
          end
        end
      rescue StandardError => e
        p e
        p e.full_message
        Hamster.report(to: 'Alim Lumanov', message: "Project #406 --download->index: Error - \n#{e}", use: :both)
      end
    end

    mark_as_finished
  end

  def list_index_cases(page)
    Nokogiri::HTML(page).css('tr.resultTableRow')
  end

  def save_cases(rows, cases_list, cases_folder)
    rows.each do |row|
      case_id = row.at('a')&.text&.strip
      next if case_id.nil?
      next if cases_list.include? case_id
      case_relative_link = row.at('a')&.attr('href')
      next if case_relative_link.nil?
      case_link = SOURCE + case_relative_link
      save_case(case_link, case_id, cases_folder)
    rescue StandardError => e
      p case_id, e
      p e.full_message
      Hamster.report(to: 'Alim Lumanov', message: "Project #406 save_cases #{case_id}: Error - \n#{e}", use: :both)
    end
  end

  def save_case(case_link, case_id, cases_folder)
    case_page = connect_to(case_link, proxy_filter: @filter, ssl_verify: false)&.body
    info_file_name = "#{case_id}"
    save_file(case_page, info_file_name, cases_folder)
    save_pdfs(case_link, case_page, case_id)
  rescue StandardError => e
    p e
    p e.full_message
    Hamster.report(to: 'Alim Lumanov', message: "Project #406 save_case #{case_id}: Error - \n#{e}", use: :both)
  end

  def save_pdfs(link, page, case_id)
    dockets = Nokogiri::HTML(page).css('table.docketlist .docketRow')
    key_start = "us_courts_expansion_#{COURT_ID}_#{case_id}_"
    case_saved_pdfs = list_case_pdfs(COURT_ID, case_id)
    case_pdfs_to_update = []
    case_pdfs_to_save = []
    case_new_pdf_urls = []
    dockets.each do |docket|
      pdf_relative_url = docket.css('td')[2].at('a.doc-pdf')&.attr('href')
      next if pdf_relative_url.nil?
      pdf_url = SOURCE + pdf_relative_url
      next if case_new_pdf_urls.include? pdf_url
      if case_saved_pdfs.include? pdf_url
        case_pdfs_to_update.push(pdf_url)
        next
      end
      case_new_pdf_urls.push(pdf_url)
      pdf_aws_url = save_to_aws(pdf_url, key_start)
      keys = %i[court_id case_id source_type aws_link source_link data_source_url]
      ok_ac_case_pdfs_on_aws = {
        run_id: @run_id,
        touched_run_id: @run_id,
        court_id: COURT_ID,
        case_id: case_id,
        source_type: 'activity',
        aws_link: pdf_aws_url,
        source_link: pdf_url,
        data_source_url: link
      }
      ok_ac_case_pdfs_on_aws[:md5_hash] = make_md5(ok_ac_case_pdfs_on_aws, keys)
      case_pdfs_to_save.push(ok_ac_case_pdfs_on_aws)
    rescue StandardError => e
      p e
      p e.full_message
      Hamster.report(to: 'Alim Lumanov', message: "Project #406 save_pdfs dockets #{case_id}: Error - \n#{pdf_url}\n#{e}", use: :both)
    end
    # binding.pry
    OkAcCasePdfsOnAWS.insert_all(case_pdfs_to_save) unless case_pdfs_to_save.empty?
    OkAcCasePdfsOnAWS.where(source_link: case_pdfs_to_update).update_all(touched_run_id: @run_id)
    OkAcCasePdfsOnAWS.where(case_id: case_id, deleted: 0).where.not(touched_run_id: @run_id).update_all "deleted = 1"
  end

  def save_to_aws(url_file, key_start)
    response = connect_to(url_file, proxy_filter: @filter, ssl_verify: false)
    body = response&.body
    # next unless response&.headers['content-type'] == "application/pdf"
    file_name = response&.headers['content-disposition'].split('=').last
    file_name = (Time.now.to_i.to_s + '.pdf') if file_name.blank?
    key = key_start + file_name
    @s3.put_file(body, key, metadata = { url: url_file })
  end

  def list_closed_cases(court_id)
    OkAcCaseInfo.where(court_id: court_id, disposition_or_status: 'Closed').pluck(:case_id).to_set
  end

  def list_case_pdfs(court_id, case_id)
    OkAcCasePdfsOnAWS.where(court_id: court_id, case_id: case_id).pluck(:source_link).to_set
  end

  def save_file(html, name, folder)
    peon.put content: html, file: name, subfolder: folder
  end

  def mark_as_started
    OkAcCaseRuns.create
    @run_id = OkAcCaseRuns.last.id
    OkAcCaseRuns.find(@run_id).update(status: 'download started')
  end

  def connect_to(*arguments, &block)
    response = nil
    3.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end
    response
  end

  def mark_as_finished
    OkAcCaseRuns.find(@run_id).update(status: 'download finished')
  end

end
