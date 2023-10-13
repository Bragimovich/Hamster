class MaxprepsComParser < Hamster::Parser

  def initialize(**page)
    super
    @html = Nokogiri::HTML(page[:html])
  end

  def parse_states
    states = html.css('select.form-control option').map do |option|
      { short_name: option['value'].downcase, name: option.text } if option['value'].size == 2
    end
    states.compact
  end

  def parse_schools_links
    links = html.css('li.gendersport').map do |li|
      link = li.at('ul.team-levels li a')['href']
      link unless link.empty?
    end
    links.compact
  end

  def count_schools
    html.css('li.gendersport').map { |li| li.at('ul.team-levels li a')['href'] }.size
  end

  def parse_player_links
    html.css('td div.TeamMainCell__StyledTeamMainCell-sc-vrm3bi-1 span a').map { |i| i['href'] }
  end

  def parse_game_scores_links
    tags_a = html.css('ul.WallPage__StyledPostList-sc-wibklf-0 li div ul li a')
    tags_a.map { |i| i['href'] if i['href'].match?(/maxpreps.com/) && i.text == 'Box Score' }.compact
  end

  def parse_home_link
    html.at('link[rel="canonical"]')['href']
  end

  def parse_schools
    schools = []
    sex     = 'Men'
    sport   = 'baseball'
    html.css('li.result.gendersport').map do |li|
      link       = li.at('div div ul.team-levels li a')['href']
      city_state = li.at('div div span.location').text.split(', ')
      city       = city_state.first unless city_state.first.match?(/[A-Z]{2}/)
      state      = city_state.last if city_state.last.match?(/[A-Z]{2}/)
      name       = li.at('div div').text.sub(li.at('div div span.location').text, '')
      nickname   = li.at('div.row-column-2')&.text&.capitalize

      schools << { sex: sex, data_source_url: link, city: city, state: state, sport: sport,
                   school_name: name, team_nickname: nickname }
    end
    schools
  end

  def parse_player
    first_name     = html.css('h1.athlete-name span')[0]&.text
    last_name      = html.css('h1.athlete-name span')[-1]&.text
    athlete_class  = html.css('div.athlete-attributes span.grade')&.text
    athlete_class  = athlete_class&.empty? ? nil : athlete_class
    url            = html.at('link[rel="canonical"]')['href'] if html.at('link[rel="canonical"]')
    puts url&.blue
    season_info    = html.at('div.season-info dl').nil? ? [] : html.at('div.season-info dl').children
    jersey_title   = season_info.find { |i| i.text.match?(/Jersey/) }
    position_title = season_info.find { |i| i.text.match?(/Pos/) }
    jersey_index   = season_info.index(jersey_title)
    position_index = season_info.index(position_title)
    if !jersey_index.nil? && jersey_index == position_index
      jersey, position = season_info[jersey_index + 1].children.map(&:text)
      jersey           = jersey.match(/\d+/).to_s.to_i
    else
      jersey   = season_info[jersey_index + 1].text.match(/\d+/).to_s.to_i if jersey_index
      position = season_info[position_index + 1].text if position_index
    end
    weight      = html.css('div.athlete-attributes span.weight')&.text&.match(/\d+/)&.to_s&.to_i
    high_school = html.css('div.athlete-name-school-name span.school-name')&.text
    city        = html.css('div.athlete-name-school-name span.school-city')&.text
    state       = html.css('div.athlete-name-school-name span.school-state')&.text
    hometown    = "#{city}, #{state}"
    height      = html.css('div.athlete-attributes span.height')&.text&.split(/[^\d]/)
    feet        = height[0]
    inches      = height[1]

    { first_name: first_name, last_name: last_name, athlete_class: athlete_class, data_source_url: url,
      position: position, jersey_number: jersey, weight: weight, high_school: high_school, hometown: hometown,
      feet: feet, inches: inches }
  end

  def parse_score
    source_url  = html.at('link[rel="canonical"]')['href']
    home_points = html.at('tr.first td.score.total.score').text
    away_points = html.at('tr.last td.score.total.score').text

    { data_source_url: url, home_team_points: home_points, away_team_points: away_points }
  end

  private

  attr_reader :html

  def correct_date(date)
    date  = date.split('/')
    month = date.shift
    day   = date.shift
    "#{date[0]}-#{month}-#{day}".to_date
  end
end
