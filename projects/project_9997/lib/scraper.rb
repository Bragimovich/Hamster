# frozen_string_literal: true
#require 'pdfkit'

require_relative '../models/us_courts_case_summary_files'

class Scraper < Hamster::Scraper
  #LOGFILE = "#{ENV['HOME']}/HarvestStorehouse/project_0349/store/project_0349_log.txt"
  COURT_ID = 25
  SPLITTER_STRING = '###BODY###'
  def initialize
    super
    # @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @s3 = AwsS3.new(bucket_key = :us_court)
  end

  def download_data
    #zip = 'southern_district_ohio_court'
    zip = 'new_york_eastern_district_court'
    files = peon.give_list(subfolder: zip)
    total = files.size
    loop do
      begin
        puts "Left #{total} cases".green
        break if files.empty?
      file_content = nil
      file_name = files.pop
      file_content = peon.give(subfolder: zip, file: file_name)
      save_to_aws(file_name, file_content)
      total -= 1
      rescue StandardError => e
        file_content = nil
      end
    end
  end

  private
  def save_to_aws(file_name, file_content)
    # cobble = Dasher.new(:using=>:cobble)
    #body = cobble.get(url_file.sub('http', 'https'))
    #file_name = url_file.split('/')[-2,2].join('_')
    case_id = file_name.split('__').last.sub('.gz', '')
    key = "PACER-source-files_#{COURT_ID}_" + case_id.sub(':', '_')
    #aws_link = "https://court-cases-activities.s3.amazonaws.com/#{key}"
    url_file = file_name.split('__').first
    url = "https://ecf.ohsd.uscourts.gov/cgi-bin/DktRpt.pl?#{url_file}"
    #p key, file_name, url
    #exit
    #exist_file = USCourtsCaseSummaryFiles.find_by(aws_link: aws_link, deleted: false)
    aws_link = @s3.put_file(file_content, key, metadata={ url: url})
    fill_aws_links_table(case_id, aws_link, url)
    #if !exist_file
  end

  def parse_case_id(file)
    doc = Nokogiri::HTML file
    main_content = doc.at_css('[id="cmecfMainContent"]')
    main_content.search('h3').children.last.text.split('#:').last.strip.split(' ').first
  end

  def split_link(file_content)
    file_content.split(SPLITTER_STRING).first
  end

  def fill_aws_links_table(case_id, aws_html_link, data_source_url)
    h_info = {}
    h_info[:court_id] = COURT_ID
    h_info[:case_id] = case_id
    h_info[:aws_html_link] = aws_html_link
    h_info[:data_source_url] = data_source_url
    h_info[:is_pacer] = 1

    existing_info = USCourtsCaseSummaryFiles.find_by(case_id: case_id, deleted: false)
    if existing_info.nil?
      hash = USCourtsCaseSummaryFiles.flail { |key| [key, h_info[key]] }
      USCourtsCaseSummaryFiles.store(hash)
    end
  end
  end
