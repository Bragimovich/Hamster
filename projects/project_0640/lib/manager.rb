# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'

URL_PAGE_PDF_CASES = 'https://www.courts.nh.gov/our-courts/supreme-court/cases-accepted'
BASE_URL = 'https://www.courts.nh.gov'

class Manager < Hamster::Harvester
  attr_accessor :parser, :keeper, :scraper

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download_case_accepted
    response = scraper.get_source(URL_PAGE_PDF_CASES)
    link = parser.get_links(response)
    links = link.map { |lin| BASE_URL + lin }

    links.each do |pdf_link|
      hash_info_court_cases = parser.parse_cases_pdf(pdf_link)
      array_md5_info = hash_info_court_cases[:case_info].map {|case_info| case_info[:md5_hash]}
      array_md5_additional_info = hash_info_court_cases[:additional_info].map {|case_info| case_info[:md5_hash]}
      case_id = hash_info_court_cases[:case_info].map {|case_info| case_info[:case_id]}

      md5_hash = { md5_info: array_md5_info, md5_add_info: array_md5_additional_info, case_id: case_id }
      keeper.insert_info(hash_info_court_cases[:case_info])
      keeper.insert_additional_info(hash_info_court_cases[:additional_info])
      keeper.insert_activities(hash_info_court_cases[:case_activity])
      keeper.insert_pdf_on_aws(hash_info_court_cases[:case_pdf_on_aws])
      keeper.insert_relations_activity_pdf(hash_info_court_cases[:case_relation])
      keeper.insert_party(hash_info_court_cases[:party_type].compact)
      keeper.update_case_accepted(md5_hash)
    end
    keeper.finish
  end

  def download_case_opinion
    first_page = 1
    years_code = [2256, 2091, 1616, 1606, 1601, 1596]
    opinion_case_url = years_code.map { |year| "https://www.courts.nh.gov/content/api/documents?type=document&q=@field_document_subcategory|=|#{year}@field_document_purpose|=|1856&filter_mode=exclusive&sort=field_date_posted|desc|ALLOW_NULLS&size=10&page=" }

    opinion_case_url.each do |case_url|
      last_page_response = scraper.get_source_case_opinion(case_url)
      last_page = parser.get_last_page(last_page_response)
      (first_page..last_page).each do |page|
        response = scraper.get_source_case_opinion(case_url, page)
        json_data = parser.get_json_and_parse(response.body)

        return if json_data.nil?
        array_md5_info = json_data[:record_info].map {|hash| hash[:md5_hash]}
        array_md5_activities = json_data[:record_activity].map {|hash| hash[:md5_hash]}
        array_md5_party = json_data[:record_party].map {|hash| hash[:md5_hash]} rescue nil
        array_md5_pdf_on_aws = json_data[:record_pdf_on_aws].map {|hash| hash[:md5_hash]}
        md5_hash = { md5_info: array_md5_info, md5_activity: array_md5_activities, md5_party: array_md5_party, md5_pdf_on_aws: array_md5_pdf_on_aws }
        case_id = json_data[:record_info].map {|case_id| case_id[:case_id]}

        keeper.insert_info(json_data[:record_info])
        keeper.update_case_info_accepted(json_data[:record_info])
        keeper.insert_activities(json_data[:record_activity])
        keeper.insert_party(json_data[:record_party].compact)
        keeper.insert_pdf_on_aws(json_data[:record_pdf_on_aws])
        keeper.insert_relations_activity_pdf(json_data[:record_relation_pdf])
        keeper.update_case_opinion(md5_hash, case_id)
      end
    keeper.finish
    end
  end
end
