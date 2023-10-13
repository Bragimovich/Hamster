# frozen_string_literal: true

require_relative 'scraper'
class AcScraper < Scraper
  def initialize(first_name, last_name, manager)
    super first_name, last_name, Scraper::COURT_TYPE_AC, manager
  end

  def scrape
    super search_options
  end

  private

  def search_options
    options = []
    party_types    = %w[ATN APLE APLT OTH]
    party_types.each do |party_type|
      form_data = {
        'lastName' => @first_name,
        'firstName' => @last_name,
        'middleName' => '',
        'partyType' => party_type,
        'filingStart' => '',
        'filingEnd' => '',
        'filingDate' => '',
        'company' => 'N',
        'courttype' => 'Y',
        'searchAppellPersonAction' => 'Search'
      }
      options << form_data
    end
    options
  end
end
