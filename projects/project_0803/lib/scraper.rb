# frozen_string_literal: true

class Scraper < Hamster::Scraper
  SEARCH_URL = 'https://data.bls.gov/cgi-bin/cpicalc.pl?'

  def fetch_page(link)
    connect_to(link)
  end

  def search_request(year1, year2)
    connect_to(url: SEARCH_URL, req_body: set_search_form_data(year1, year2), method: :post)
  end
  
  def set_search_form_data(cost1 = 1, year1, year2)
    year1 = year1.to_s + "01"
    year2 = year2.to_s + "01"
    form_data = {
      "cost1" => cost1,
      "year1" => year1,
      "year2" => year2,
    }
    form_data.to_a.map { |val| val[0] + "=" + val[1].to_s }.join("&")
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304, 302, 307].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    logger.info '=================================='
    logger.info 'Response status: '.indent(1, "\t")
    status = response&.status
    if status == 200
      logger.info status 
    else
      logger.error status 
    end
    logger.info '=================================='
  end

end
