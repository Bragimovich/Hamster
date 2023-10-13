class Scraper <  Hamster::Scraper

  def files_downloading(year_wise_data, last_two_digit)
    url = "https://www2.census.gov/programs-surveys/cbp/datasets/#{year_wise_data}/zbp#{last_two_digit}detail.zip"
    connect_to(url)
  end

  def county_state
    url = "https://www2.census.gov/programs-surveys/cbp/technical-documentation/reference/state-county-geography-reference/georef12.txt"
    connect_to(url)
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
end
