# frozen_string_literal: true

require_relative 'scraper'
class DcScraper < Scraper
  def initialize(first_name, last_name, manager)
    super first_name, last_name, Scraper::COURT_TYPE_DC, manager
  end

  def scrape
    super search_options
  end

  private

  def search_options
    options      = []
    court_system = %w[C D]
    case_types   = %w[CIVIL CRIMINAL TRAFFIC CP]
    counties    = %w[
      ALLEGANY\ COUNTY
      ANNE\ ARUNDEL\ COUNTY
      BALTIMORE\ CITY
      BALTIMORE\ COUNTY
      CALVERT\ COUNTY
      CAROLINE\ COUNTY
      CARROLL\ COUNTY
      CECIL\ COUNTY
      CHARLES\ COUNTY
      DORCHESTER\ COUNTY
      FREDERICK\ COUNTY
      GARRETT\ COUNTY
      HARFORD\ COUNTY
      HOWARD\ COUNTY
      KENT\ COUNTY
      MONTGOMERY\ COUNTY
      PRINCE\ GEORGE'S\ COUNTY
      QUEEN\ ANNE'S\ COUNTY
      SAINT\ MARY'S\ COUNTY
      SOMERSET\ COUNTY
      TALBOT\ COUNTY
      WASHINGTON\ COUNTY
      WICOMICO\ COUNTY
      WORCESTER\ COUNTY
    ]
    counties.product(court_system, case_types).each do |option|
      form_data = {
        'lastName' => @first_name,
        'firstName' => @last_name,
        'company' => 'N',
        'courttype' => 'N',
        'middleName' => '',
        'partyType' => '',
        'filingStart' => '',
        'filingEnd' => '',
        'filingDate' => '',
        'countyName' => option[0],
        'courtSystem' => option[1],
        'site' => option[2],
        'searchTrialPersonAction' => 'Search'
      }
      options << form_data
    end
    options
  end
end
