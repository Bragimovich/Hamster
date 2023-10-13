class Scraper < Hamster::Scraper

  def district_file
    connect_to(url: "https://profiles.doe.mass.edu/search/search_export.aspx?orgCode=&orgType=5,12&runOrgSearch=Y&searchType=ORG&leftNavId=11238&showEmail=N")
  end

  def school_file
    connect_to("https://profiles.doe.mass.edu/search/search_export.aspx?orgCode=&orgType=6,13&runOrgSearch=Y&searchType=ORG&leftNavId=11238&showEmail=N")
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
