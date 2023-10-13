# frozen_string_literal: true
require_relative '../models/federal_register_forecasted_notices'

class ParserClass < Hamster::Parser
  MAIN_PAGE = 'https://www.federalregister.gov/public-inspection/current'

  def initialize
    super
    @already_inserted_links = FederalRegisterForecastedNotices.pluck(:link)
  end

  def parse(file_content)
    data = JSON.parse(file_content)
    results = data["results"]
    return [] if results.nil?
    puts "Found #{results.count} results"
    data_array = []
    results.each do |result|
      html_url = result["html_url"].strip rescue nil
      next if @already_inserted_links.include? html_url
      filed_at = DateTime.strptime(result["filed_at"].strip) rescue nil
      pdf_updated_at = DateTime.strptime(result["pdf_updated_at"].strip) rescue nil
      publication_date = Date.parse(result["publication_date"].strip).to_date  rescue nil
      page_views_as_of = DateTime.parse(result["page_views"]["last_updated"].strip)  rescue nil
      page_views = result["page_views"]["count"] rescue nil
      document_number = result["document_number"].strip rescue nil
      num_pages = result["num_pages"] rescue nil
      agency_names = result["agency_names"].first.strip rescue nil
      type = result["type"].strip rescue nil
      pdf_url = result["pdf_url"].strip rescue nil
      title = result["title"].strip rescue nil
      data_hash = {
        title: title,
        filed_at: filed_at,
        scheduled_publication_date: publication_date,
        agency: agency_names,
        document_type: type,
        pages: num_pages,
        document_number: document_number,
        page_views: page_views,
        page_views_as_of: page_views_as_of,
        link: html_url,
        pdf_link: pdf_url,
        aws_pdf_link: nil,
        pdf_appeared: pdf_updated_at,
        data_source_url: MAIN_PAGE
      }
      data_array.append(data_hash)
    end
    data_array
  end
end
  