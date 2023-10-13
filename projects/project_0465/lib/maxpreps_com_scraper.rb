require_relative '../lib/maxpreps_com_parser'
require_relative '../lib/maxpreps_com_keeper'

class MaxprepsComScraper < Hamster::Scraper

  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @count        = 0
    @keeper       = keeper
    @run_id       = keeper.run_id
  end

  attr_reader :count

  def scrape_site
    genders_sports = [{ 'boys' => ['baseball'] }, { 'girls' => [] }]
    genders_sports.each do |gender_sport|
      gender = gender_sport.first.first
      sports = gender_sport.values.first
      sports.each do |sport|
        base_url      = "https://www.maxpreps.com/search/default.aspx?type=school&search=&state=&gendersport=#{gender},#{sport}"
        base_page     = get_response(base_url)&.body
        parser_states = MaxprepsComParser.new(html: base_page)
        states        = parser_states.parse_states
        states.each_with_index do |state, index|
          school_url = "https://www.maxpreps.com/search/default.aspx?type=school&search=&state=#{state[:short_name]}&gendersport=#{gender},#{sport}"
          puts "#{state[:name]} -- #{index} -- #{school_url}".green
          schools_page = get_response(school_url)&.body
          peon.put(file: state[:short_name], content: schools_page, subfolder: "#{run_id}_#{gender}_#{sport}_schools_page")
          parser = MaxprepsComParser.new(html: schools_page)
          school_links = parser.parse_schools_links
          save_pages(school_links, sport, gender, state[:short_name])

          if parser.count_schools >= 200
            cities = keeper.get_cities(state[:name])
            cities.each do |city|
              school_url = "https://www.maxpreps.com/search/default.aspx?type=school&search=#{city}&state=#{state[:short_name]}&gendersport=#{gender},#{sport}"
              puts "City -- #{city} -- #{state[:name]} -- #{index} -- #{school_url}".green
              schools_page = get_response(URI.escape(school_url))&.body
              parser       = MaxprepsComParser.new(html: schools_page)
              school_links = parser.parse_schools_links
              next unless school_links.any?

              name = "#{state[:short_name]}_#{city}".gsub(' ', '_').gsub("'", '').gsub('(', '').gsub(')', '').gsub(',', '').gsub("/", '_')
              peon.put(file: name, content: schools_page, subfolder: "#{run_id}_#{gender}_#{sport}_schools_page")
              save_pages(school_links, sport, gender, state[:short_name])
            end
          end
          Hamster.report(to: 'Eldar Eminov', message: "Finish the #{state[:name]} -- #{index}", use: :both)
        end
      end
    end
  rescue StandardError => e
    puts "#{e} | #{e.backtrace}"
    Hamster.report(to: 'Eldar Eminov', message: e, use: :both)
  end

  private

  attr_reader :keeper, :run_id

  def save_pages(school_links, sport, gender, state)
    school_links.each_with_index do |link, idx|
      puts "#{state} -- #{idx} school -- #{link}".green
      md5 = MD5Hash.new(columns: [:link])
      md5.generate(link: link)
      school       = md5.hash
      home_page    = get_response(link) { self }.body
      peon.put(file: school, content: home_page, subfolder: "#{run_id}_#{gender}_#{sport}_schools_home_pages")
      parser_home  = MaxprepsComParser.new(html: home_page)
      scores_links = parser_home.parse_game_scores_links
      scores_links.each do |url|
        puts "#{state} -- #{idx} school -- #{url}".green
        md5 = MD5Hash.new(columns: [:url])
        md5.generate(url: url)
        score = md5.hash
        subfolder = "#{run_id}_#{gender}_#{sport}_#{school}_scores_pages"
        if page_exist?(subfolder, score)
          puts "Skipped #{score} this file exists".blue
          next
        end
        scores_page = get_response(url) { self }.body
        peon.put(file: score, content: scores_page, subfolder: subfolder)
      end
      roster_link = "#{link}roster/"
      puts "#{state} -- #{idx} school -- #{roster_link}".green
      roster_page  = get_response(roster_link) { self }.body
      parser       = MaxprepsComParser.new(html: roster_page)
      player_links = parser.parse_player_links
      player_links.each do |url|
        puts "#{state} -- #{idx} school -- #{url}".green
        md5 = MD5Hash.new(columns: [:url])
        md5.generate(url: url)
        player    = md5.hash
        subfolder = "#{run_id}_#{gender}_#{sport}_#{school}_player_pages"
        if page_exist?(subfolder, player)
          puts "Skipped #{player} this file exists".blue
          next
        end
        player_page = get_response(URI.escape(url)) { self }.body
        peon.put(file: player, content: player_page, subfolder: subfolder)
      end
      @count += 1
    end
  end

  def page_exist?(subfolder, name)
    name += '.gz'
    peon.give_list(subfolder: subfolder).include?(name)
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 301, 304, 308].include?(response.status)
    end
    if [301, 308].include?(response&.status)
      redirected_link = response.headers['location']
      get_response(redirected_link) { self }
    else
      response
    end
  end

  def get_response(url, &block)
    filter = @proxy_filter
    filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(url, proxy_filter: filter, ssl_verify: false, &block)
  end
end
