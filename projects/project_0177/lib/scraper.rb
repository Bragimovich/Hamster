require_relative 'parser'

class Scraper < Hamster::Scraper
  SOURCE = 'https://gasprices.aaa.com'
  STATES = { US: "National",
             AK: "Alaska",
             AL: "Alabama",
             AR: "Arkansas",
             AZ: "Arizona",
             CA: "California",
             CO: "Colorado",
             CT: "Connecticut",
             DC: "District of Columbia",
             DE: "Delaware",
             FL: "Florida",
             GA: "Georgia",
             HI: "Hawaii",
             IA: "Iowa",
             ID: "Idaho",
             IL: "Illinois",
             IN: "Indiana",
             KS: "Kansas",
             KY: "Kentucky",
             LA: "Louisiana",
             MA: "Massachusetts",
             MD: "Maryland",
             ME: "Maine",
             MI: "Michigan",
             MN: "Minnesota",
             MO: "Missouri",
             MS: "Mississippi",
             MT: "Montana",
             NC: "North Carolina",
             ND: "North Dakota",
             NE: "Nebraska",
             NH: "New Hampshire",
             NJ: "New Jersey",
             NM: "New Mexico",
             NV: "Nevada",
             NY: "New York",
             OH: "Ohio",
             OK: "Oklahoma",
             OR: "Oregon",
             PA: "Pennsylvania",
             RI: "Rhode Island",
             SC: "South Carolina",
             SD: "South Dakota",
             TN: "Tennessee",
             TX: "Texas",
             UT: "Utah",
             VA: "Virginia",
             VT: "Vermont",
             WA: "Washington",
             WI: "Wisconsin",
             WV: "West Virginia",
             WY: "Wyoming" }

  def initialize(keeper)
    super
    @keeper = keeper
    @count  = 0
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
  end

  attr_reader :count

  def scrape
    page      = get_page(SOURCE)
    parser    = Parser.new
    @web_date = parser.parse_web_date(page)
    db_date   = keeper.get_last_date
    save_pages if db_date < @web_date
  end

  private

  attr_reader :keeper

  def get_page(url)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(url, proxy_filter: @filter, ssl_verify: false)&.body
  end

  def save_pages
    links = STATES.keys.map { |s| SOURCE + '/?state=' + s.to_s }
    links.each do |link|
      html = get_page(link)
      save_file(html, link)
    end
  end

  def save_file(html, link)
    name = link[-2..-1]
    peon.put(content: html, file: "#{name}_#{@web_date}", subfolder: "#{keeper.run_id}_prices")
    @count += 1
  end
end
