require_relative 'scraper'

class Scraper < Hamster::Scraper
  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @count        = 0
    @keeper       = keeper
    @run_id       = keeper.run_id
  end

  attr_reader :count

  def scrape
    base_url      = "https://www.maxpreps.com/schools/"
    base_page     = response(base_url)
    parser_states = Parser.new(html: base_page)
    states        = parser_states.parse_states
    #[{:short_name=>"tx", :name=>"Texas"},{:short_name=>"il", :name=>"Illinois"}]
    states.each do |state|
      school_url = "https://www.maxpreps.com/#{state[:short_name]}/schools/"
      Hamster.logger.debug "#{state[:name]} | #{school_url}".green
      sleep rand(0.5..1.5)

      schools_page = response(school_url)
      parser       = Parser.new(html: schools_page)
      school_links = parser.parse_schools_links
      school_links.size >= 200 ? save_with_city(state[:short_name]) : save_pages(school_links, state[:short_name])

      Hamster.logger.info "#{state[:short_name]} scrap ended."
    end
  end

  def return_gmap_page(url)
    response(url)
  end

  private

  attr_reader :keeper, :run_id

  def save_with_city(state)
    cities = keeper.get_cities(state)
    cities.each do |city|
      school_url = "https://www.maxpreps.com/#{state}/schools/#{city}"
      Hamster.logger.debug "#{city} | #{state} | #{school_url}".green

      schools_page = response(URI.escape(school_url))
      parser       = Parser.new(html: schools_page)
      school_links = parser.parse_schools_links
      next unless school_links.any?

      save_pages(school_links, state[:short_name])
    end
  end

  def save_pages(school_links, state)
    size = school_links.size
    school_links.each_with_index do |link, idx|
      Hamster.logger.debug "#{state} | #{idx+1} of #{size} | #{link}".green
      md5 = MD5Hash.new(columns: [:link])
      md5.generate(link: link)
      school    = md5.hash
      home_page = response(link)
      peon.put(file: school, content: home_page, subfolder: "#{run_id}_schools/#{state}")
      @count += 1
    end
  end

  def response(*arguments)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(arguments[0], proxy_filter: @proxy_filter, ssl_verify: false)
  end

  def connect_to(*arguments)
    response = nil
    10.times do
      response = super(*arguments)
      #need logic for redirect
      break if response&.status && [200, 304].include?(response.status)
    end
    response&.body
  end
end
