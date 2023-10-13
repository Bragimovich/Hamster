class Scraper <  Hamster::Scraper

  def call_api(offset)
    connect_to("https://cthru.data.socrata.com/resource/rxhc-k6iz.json?$limit=20000&$offset=#{offset}")
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
end
