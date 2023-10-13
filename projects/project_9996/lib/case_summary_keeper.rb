# frozen_string_literal: true
require_relative '../models/us_case_pdf_on_aws'

class NYCaseSummaryKeeper < Hamster::Scraper

  def store_data(court_id, case_id, aws_link, aws_html_link, data_source_url)
  begin
  h = {}
  h[:court_id] = court_id
  h[:case_id] = case_id
  h[:source_type] = 'info'
  h[:aws_link] = aws_link
  h[:source_link] = data_source_url
  h[:aws__html_link] = aws_html_link
  h[:data_source_url] = data_source_url
  data = { court_id: h[:court_id], case_id: h[:case_id], aws_link: h[:aws_link], source_link: h[:source_link]}
  md5_aws = MD5Hash.new(columns: data.keys)
  md5_aws.generate(data)
  md5_aws = md5_aws.hash
  h[:md5_hash] = md5_aws
  h[:run_id] = 1
  h[:touched_run_id] = 1
  h[:deleted] = 0

  p h
  existing_info = USCasePDFAWS.find_by(md5_hash: md5_aws, deleted: false)

  if existing_info.nil?
    hash = USCasePDFAWS.flail { |key| [key, h[key]] }
    USCasePDFAWS.store(hash)
  else
    #existing_info.update(touched_run_id: @run_id)
  end
  USCasePDFAWS.clear_active_connections!
  end
  rescue => e
  end
end
