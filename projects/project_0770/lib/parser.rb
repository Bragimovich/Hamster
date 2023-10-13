# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse_career_stats(stats_json)
    json = parse_json(stats_json).dig('stats')&.first
    group  = json&.dig('group', 'displayName')
    splits = json&.dig('splits')
    return [] if splits.nil?

    pitching   = group == 'pitching'
    stats_list = []
    splits.each do |split|
      stats_data = {}
      stats_data[:mlb_team_id]     = split.dig('team', 'id')
      stats_data[:mlb_person_id]   = split.dig('player', 'id')
      stats_data[:season]          = split['season']
      stats_data[:league]          = split.dig('team', 'league', 'abbreviation')
      stats_data[:level]           = split.dig('sport', 'abbreviation')
      stats_data[:group]           = group
      stats_data[:wins]            = pitching ? split.dig('stat', 'wins') : nil
      stats_data[:losses]          = pitching ? split.dig('stat', 'losses') : nil
      stats_data[:era]             = pitching ? split.dig('stat', 'era') : nil
      stats_data[:games]           = split.dig('stat', 'gamesPlayed')
      stats_data[:games_started]   = pitching ? split.dig('stat', 'gamesStarted') : nil
      stats_data[:complete_games]  = pitching ? split.dig('stat', 'completeGames') : nil
      stats_data[:shutouts]        = pitching ? split.dig('stat', 'shutouts') : nil
      stats_data[:holds]           = pitching ? split.dig('stat', 'holds') : nil
      stats_data[:saves]           = pitching ? split.dig('stat', 'saves') : nil
      stats_data[:save_opp]        = pitching ? split.dig('stat', 'saveOpportunities') : nil
      stats_data[:innings_pitched] = pitching ? split.dig('stat', 'inningsPitched') : nil
      stats_data[:hits]            = split.dig('stat', 'hits')
      stats_data[:runs]            = split.dig('stat', 'runs')
      stats_data[:earned_runs]     = pitching ? split.dig('stat', 'earnedRuns') : nil
      stats_data[:home_runs]       = split.dig('stat', 'homeRuns')
      stats_data[:no_of_pitches]   = split.dig('stat', 'numberOfPitches')
      stats_data[:hit_batsmen]     = pitching ? split.dig('stat', 'hitBatsmen') : nil
      stats_data[:base_on_balls]   = split.dig('stat', 'baseOnBalls')
      stats_data[:intent_walks]    = split.dig('stat', 'intentionalWalks')
      stats_data[:strikeouts]      = split.dig('stat', 'strikeOuts')
      stats_data[:batting_avg]     = split.dig('stat', 'avg')
      stats_data[:whip]            = pitching ? split.dig('stat', 'whip') : nil
      stats_data[:go_ao]           = split.dig('stat', 'groundOutsToAirouts')
      stats_data[:at_bats]         = split.dig('stat', 'atBats')
      stats_data[:total_bases]     = split.dig('stat', 'totalBases')
      stats_data[:doubles]         = split.dig('stat', 'doubles')
      stats_data[:triples]         = split.dig('stat', 'triples')
      stats_data[:rbi]             = pitching ? nil : split.dig('stat', 'rbi')
      stats_data[:stolen_bases]    = split.dig('stat', 'stolenBases')
      stats_data[:caught_stealing] = split.dig('stat', 'caughtStealing')
      stats_data[:obp]             = split.dig('stat', 'obp')
      stats_data[:slg]             = split.dig('stat', 'slg')
      stats_data[:ops]             = split.dig('stat', 'ops')

      stats_data[:season] += '_overall' if stats_data[:mlb_team_id].nil? || split.key?('numTeams')
      stats_list << stats_data
    end
    stats_list
  end

  def parse_game(game_json)
    game_result   = nil
    linescore_res = nil
    batters_res   = nil
    pitchers_res  = nil
    addition_res  = nil

    json      = parse_json(game_json)
    game_data = json['gameData']
    live_data = json['liveData']

    if game_data.nil? || live_data.nil?
      logger.info 'Failed to parse game details JSON.'
      logger.info game_json
      raise 'Failed to parse game details JSON.'
    end

    game_id       = game_data.dig('game', 'pk')
    game_season   = game_data.dig('game', 'season')
    game_finished = game_data.dig('status', 'detailedState') == 'Final'
    home_team_id  = game_data.dig('teams', 'home', 'id')
    away_team_id  = game_data.dig('teams', 'away', 'id')

    # Collect game data
    game_result = {}
    game_result[:mlb_id]           = game_id
    game_result[:mlb_home_team_id] = home_team_id
    game_result[:mlb_away_team_id] = away_team_id

    game_result[:home_rec_after] =
      if game_finished
        h_win = game_data.dig('teams', 'home', 'record', 'leagueRecord', 'wins')
        h_los = game_data.dig('teams', 'home', 'record', 'leagueRecord', 'losses')
        "#{h_win}-#{h_los}"
      else
        nil
      end

    game_result[:away_rec_after] =
      if game_finished
        a_win = game_data.dig('teams', 'away', 'record', 'leagueRecord', 'wins')
        a_los = game_data.dig('teams', 'away', 'record', 'leagueRecord', 'losses')
        "#{a_win}-#{a_los}"
      else
        nil
      end

    game_date_time = DateTime.parse(game_data.dig('datetime', 'dateTime')) rescue nil

    game_result[:game_datetime]  = game_date_time&.strftime('%Y-%m-%d %H:%M:%S')
    game_result[:venue_name]     = game_data.dig('venue', 'name')
    game_result[:venue_address]  = game_data.dig('venue', 'location', 'address1')
    game_result[:venue_city]     = game_data.dig('venue', 'location', 'city')
    game_result[:venue_zip]      = game_data.dig('venue', 'location', 'postalCode')
    game_result[:venue_state]    = game_data.dig('venue', 'location', 'stateAbbrev')
    game_result[:venue_timezone] = game_data.dig('venue', 'timeZone', 'id')
    game_result[:venue_tz_abbr]  = game_data.dig('venue', 'timeZone', 'tz')

    return [game_result] unless game_finished

    # Collect score by innings
    home_hash = { mlb_game_id: game_id, mlb_team_id: home_team_id }
    away_hash = { mlb_game_id: game_id, mlb_team_id: away_team_id }
    scores   = []
    innings      = live_data.dig('linescore', 'innings')
    unless innings.nil?
      innings.each do |inning|
        key = "inning_#{inning['num']}"
        scores << home_hash.merge({ score_key: key, score_val: inning.dig('home', 'runs') })
        scores << away_hash.merge({ score_key: key, score_val: inning.dig('away', 'runs') })
      end
    end

    scores << home_hash.merge({ score_key: 'runs', score_val: live_data.dig('linescore', 'teams', 'home', 'runs') })
    scores << home_hash.merge({ score_key: 'hits', score_val: live_data.dig('linescore', 'teams', 'home', 'hits') })
    scores << home_hash.merge({ score_key: 'errors', score_val: live_data.dig('linescore', 'teams', 'home', 'errors') })
    scores << away_hash.merge({ score_key: 'runs', score_val: live_data.dig('linescore', 'teams', 'away', 'runs') })
    scores << away_hash.merge({ score_key: 'hits', score_val: live_data.dig('linescore', 'teams', 'away', 'hits') })
    scores << away_hash.merge({ score_key: 'errors', score_val: live_data.dig('linescore', 'teams', 'away', 'errors') })

    linescore_res = scores

    # Collect batters & pitchers stat
    home_batters  = live_data.dig('boxscore', 'teams', 'home', 'batters') || []
    home_pitchers = live_data.dig('boxscore', 'teams', 'home', 'pitchers') || []
    away_batters  = live_data.dig('boxscore', 'teams', 'away', 'batters') || []
    away_pitchers = live_data.dig('boxscore', 'teams', 'away', 'pitchers') || []
    home_batters  = home_batters.map(&:to_i)
    home_pitchers = home_pitchers.map(&:to_i)
    away_batters  = away_batters.map(&:to_i)
    away_pitchers = away_pitchers.map(&:to_i)
    home_batters -= home_pitchers
    away_batters -= away_pitchers

    home_batters = home_batters.map do |batter|
      [home_team_id, live_data.dig('boxscore', 'teams', 'home', 'players', "ID#{batter}")]
    end
    away_batters = away_batters.map do |batter|
      [away_team_id, live_data.dig('boxscore', 'teams', 'away', 'players', "ID#{batter}")]
    end
    home_pitchers = home_pitchers.map do |pitcher|
      [home_team_id, live_data.dig('boxscore', 'teams', 'home', 'players', "ID#{pitcher}")]
    end
    away_pitchers = away_pitchers.map do |pitcher|
      [away_team_id, live_data.dig('boxscore', 'teams', 'away', 'players', "ID#{pitcher}")]
    end

    batters_res =
      (home_batters + away_batters).map do |batter|
        team_id     = batter.first
        player_data = batter.last
        next nil if player_data.nil?

        {
          mlb_game_id:   game_id,
          mlb_team_id:   team_id,
          mlb_person_id: player_data.dig('person', 'id'),
          season:        game_season,
          position:      player_data.dig('position', 'abbreviation'),
          at_bats:       player_data.dig('stats', 'batting', 'atBats'),
          runs:          player_data.dig('stats', 'batting', 'runs'),
          hits:          player_data.dig('stats', 'batting', 'hits'),
          rbi:           player_data.dig('stats', 'batting', 'rbi'),
          base_on_balls: player_data.dig('stats', 'batting', 'baseOnBalls'),
          strike_outs:   player_data.dig('stats', 'batting', 'strikeOuts'),
          left_on_base:  player_data.dig('stats', 'batting', 'leftOnBase'),
          avg:           player_data.dig('seasonStats', 'batting', 'avg'),
          ops:           player_data.dig('seasonStats', 'batting', 'ops'),
          :'2B'       => nil,
          :'3B'       => nil,
          HR:            nil
        }
      end
      .compact

    ['home', 'away'].each do |side|
      batting_info = live_data.dig('boxscore', 'teams', side, 'info')&.find { |i| i['title'] == 'BATTING' }
      next if batting_info.nil?

      players_map = live_data.dig('boxscore', 'teams', side, 'players').map do |_, player_data|
        name_coms = player_data.dig('person', 'fullName')&.split(' ') || []
        next nil if name_coms.size.zero?
        initials  = name_coms.last
        initials += ", #{name_coms.first.first.upcase}" if name_coms.size > 1

        {
          id:        player_data.dig('person', 'id').to_i,
          last_name: name_coms.last,
          initials:  initials
        }
      end
      .compact

      batting_info.dig('fieldList')&.each do |field|
        label = field['label']
        next unless ['2B', '3B', 'HR'].include?(label)

        value  = field['value']
        value  = value.gsub(/\.$/, '')
        values = value.split(';').map(&:strip)
        values.each do |val|
          match_data = /([^\(]*)\(([^\)]*)\)/.match(val)
          next if match_data.size != 3

          name    = match_data[1].strip
          cont    = match_data[2].strip
          initial = name.split(/[^a-zA-Z]/).reject(&:empty?).size > 1

          player = players_map.find do |p|
            p_name = initial ? p[:initials] : p[:last_name]
            p_name == name
          end
          next if player.nil?

          batter_idx = batters_res.find_index { |bat| bat[:mlb_person_id].to_i == player[:id] }
          next if batter_idx.nil?

          batters_res[batter_idx][label.to_sym] = cont
        end
      end
    end

    pitchers_res =
      (home_pitchers + away_pitchers).map do |pitcher|
        team_id     = pitcher.first
        player_data = pitcher.last
        next nil if player_data.nil?

        {
          mlb_game_id:     game_id,
          mlb_team_id:     team_id,
          mlb_person_id:   player_data.dig('person', 'id'),
          season:          game_season,
          note:            player_data.dig('stats', 'pitching', 'note'),
          innings_pitched: player_data.dig('stats', 'pitching', 'inningsPitched'),
          hits:            player_data.dig('stats', 'pitching', 'hits'),
          runs:            player_data.dig('stats', 'pitching', 'runs'),
          earned_runs:     player_data.dig('stats', 'pitching', 'earnedRuns'),
          base_on_balls:   player_data.dig('stats', 'pitching', 'baseOnBalls'),
          strike_outs:     player_data.dig('stats', 'pitching', 'strikeOuts'),
          home_runs:       player_data.dig('stats', 'pitching', 'homeRuns'),
          era:             player_data.dig('seasonStats', 'pitching', 'era')
        }
      end
      .compact

    # Collect game additional info
    boxscore_info = live_data.dig('boxscore', 'info')
    unless boxscore_info.nil?
      addition_res = {
        game_duration: nil,
        attendance:    nil,
        weather:       nil,
        wind:          nil,
        first_pitch:   nil,
        umpires:       nil
      }

      boxscore_info.each do |info|
        value = info['value']&.strip&.gsub(/\.$/, '')
        addition_res[:game_duration] = value if info['label'] == 'T'
        addition_res[:attendance]    = value if info['label'] == 'Att'
        addition_res[:weather]       = value if info['label'] == 'Weather'
        addition_res[:wind]          = value if info['label'] == 'Wind'
        addition_res[:first_pitch]   = value if info['label'] == 'First pitch'
        addition_res[:umpires]       = value if info['label'] == 'Umpires'
      end

      unless addition_res[:attendance].nil?
        addition_res[:attendance] = addition_res[:attendance].gsub(',', '')
      end

      if addition_res.compact.size > 0
        addition_res[:mlb_game_id] = game_id
      else
        addition_res = nil
      end
    end

    [game_result, linescore_res, batters_res, pitchers_res, addition_res]
  end

  def parse_organizations(orgs_json)
    orgs = parse_json(orgs_json)
    orgs = orgs['teams']
    orgs.map do |org|
      {
        division: org.dig('division', 'nameShort'),
        id:       org['id'].to_i,
        name:     org['name']
      }
    end
  end

  def parse_person(person_html, person_json, basic_data)
    person_data = basic_data.dup
    person_doc  = Nokogiri::HTML(person_html)
    photo_img   = person_doc.xpath('//section[@id="player"]/header[@id="player-header"]//img[contains(@class, "player-headshot")]')
    bio_body    = person_doc.xpath('//div[@id="playerBioModalBody"]')

    person_data[:org_img_url] = photo_img.size > 0 ? photo_img[0]['src'] : nil
    person_data[:bio_info] = bio_body.size > 0 ? bio_body[0].inner_html : nil
    if !person_data[:bio_info].nil? && person_data[:bio_info].size > 16380
      person_data[:bio_info] = person_data[:bio_info][0..16379]
    end

    json = parse_json(person_json).dig('people')&.first
    school  = json.dig('education', 'highschools')&.first
    college = json.dig('education', 'colleges')&.first
    twitter = json.dig('social', 'twitter')&.join(', ')
    insta   = json.dig('social', 'instagram')&.join(', ')
    drafts  = json.dig('drafts')
    drafts  = drafts.sort_by { |d| d['year'].to_i } unless drafts.nil?
    draft   = drafts&.last

    person_data[:current_team_id]    = json.dig('currentTeam', 'id')
    person_data[:full_name]          = json['fullFMLName']
    person_data[:alias]              = json['fullName']
    person_data[:first_name]         = json['firstName']
    person_data[:middle_name]        = json['middleName']
    person_data[:last_name]          = json['lastName']
    person_data[:full_position]      = json.dig('primaryPosition', 'type')
    person_data[:number]             = json['primaryNumber']
    person_data[:b_t]                = "#{json.dig('batSide', 'code')}/#{json.dig('pitchHand', 'code')}"
    person_data[:height]             = json['height']
    person_data[:weight]             = json['weight']
    person_data[:birth_date]         = Date.strptime(json['birthDate'], '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil
    person_data[:country]            = json['birthCountry']
    person_data[:city]               = json['birthCity']
    person_data[:state]              = json['birthStateProvince']
    person_data[:mlb_debut]          = Date.strptime(json['mlbDebutDate'], '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil
    person_data[:college_name]       = college&.dig('name')
    person_data[:college_city]       = college&.dig('city')
    person_data[:college_state]      = college&.dig('state')
    person_data[:high_school_name]   = school&.dig('name')
    person_data[:high_school_city]   = school&.dig('city')
    person_data[:high_school_state]  = school&.dig('state')
    person_data[:instagram]          = insta
    person_data[:twitter]            = twitter
    person_data[:draft_year]         = draft&.dig('year')
    person_data[:draft_team]         = draft&.dig('team', 'name')
    person_data[:draft_round]        = draft&.dig('pickRound')
    person_data[:draft_overall_pick] = draft&.dig('pickNumber')

    person_data
  end

  def parse_person_list(roster_html)
    roster_html = roster_html.gsub(/<tbody([^<>]*)</, '<tbody\1><')
    doc = Nokogiri::HTML(roster_html)
    player_rows = doc.xpath('//div[contains(@class, "players")]/table[contains(@class, "roster__table")]/tbody/tr')
    player_rows.map do |row|
      id_col = row.xpath('td[contains(@class, "info")]/a[contains(@class, "player-link")]')
      fourty = row.xpath('td[contains(@class, "fortyMan")]/text()')
      status = row.xpath('td[contains(@class, "status")]/div[contains(@class, "status-div")]/text()')
      next nil if id_col.size.zero?

      mlb_id = id_col[0]['data-playerid']
      status = status[0]&.text || ''
      fourty = fourty[0]&.text || ''

      {
        mlb_40_man: fourty.downcase == 'yes',
        mlb_id:     mlb_id.to_i,
        status:     status
      }
    end
    .compact
  end

  def parse_schedules(schedules_json)
    dates = parse_json(schedules_json)['dates']
    if dates.nil?
      logger.info 'Failed to parse schedules JSON.'
      logger.info schedules_json
      raise 'Failed to parse schedules JSON.'
    end

    dates.map do |date|
      games = date['games']
      next nil if games.nil? || games.size.zero?
      games.map do |game|
        next nil if game.key?('resumeGameDate') || game.key?('rescheduleGameDate')

        game_status = game.dig('status', 'detailedState')
        next nil if game_status == 'Cancelled'

        game_finished = game_status == 'Final'
        makeup_date   = game['resumedFromDate'] || game['rescheduledFromDate']
        makeup_date   = Date.strptime(makeup_date, '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil

        game_desc = game['description']
        if game_desc.nil? && !game['resumedFromDate'].nil?
          resumed_from = Date.strptime(game['resumedFromDate'], '%Y-%m-%d').strftime('%b %-d') rescue nil
          unless resumed_from.nil?
            game_desc = "Completion of game suspended on #{resumed_from}"
          end
        end

        if game_desc.nil? && !game['promotions'].nil?
          game_desc = game['promotions'].first&.dig('name')
        end

        {
          add_info:        game_desc,
          away_score:      game_finished ? game.dig('teams', 'away', 'score') : nil,
          day_game_number: game['gameNumber'],
          home_score:      game_finished ? game.dig('teams', 'home', 'score') : nil,
          id:              game['gamePk'].to_i,
          makeup_date:     makeup_date
        }
      end
    end
    .flatten
    .compact
  end

  def parse_teams(teams_html, orgs_data)
    match_data = teams_html.match(/window.team_info\s?=\s?(\[[^;]*\]);/)
    if match_data.nil? || match_data.size != 2
      logger.info 'Failed to parse team info.'
      logger.info teams_html
      raise 'Failed to parse team info'
    end

    teams = parse_json(match_data[1])
    teams = teams.select do |team|
      team['active'] && ['Triple-A', 'Double-A', 'High-A', 'Single-A'].include?(team.dig('sport', 'name'))
    end

    teams.map do |team|
      org = orgs_data.find { |o| o[:id] == team['parentOrgId'].to_i }
      next nil if org.nil?

      {
        abbr:     team['abbreviation'],
        division: org[:division],
        id:       team['id'],
        level:    team.dig('sport', 'name'),
        name:     team['name'],
        parent:   org[:name],
        slug:     team['slug']
      }
    end
    .compact
  end

  def parse_transactions(trans_html)
    trans_doc = Nokogiri::HTML(trans_html)
    trans_div = trans_doc.xpath('//div[@id="transactions"]')
    if trans_div.size.zero?
      logger.info 'Failed to parse transaction HTML.'
      logger.info trans_html
      raise 'Failed to parse transaction HTML.'
    end

    trans_rows = trans_div[0].xpath('//table[contains(@class, "roster__table")]/tbody/tr')
    trans_rows.map do |row|
      date_str  = row.xpath('td[contains(@class, "date")]/text()').first&.text
      trans_str = row.xpath('td[contains(@class, "description")]').first&.inner_text&.strip
      player_id = row.xpath('td[contains(@class, "description")]//a[contains(@class, "player-link")]').first
      player_id = player_id['data-playerid'] unless player_id.nil?

      trans_date = Date.strptime(date_str, '%m/%d/%y').strftime('%Y-%m-%d') rescue nil
      trans_date ||= Date.strptime(date_str, '%m/%d/%Y').strftime('%Y-%m-%d') rescue nil
      trans_date ||= Date.strptime(date_str, '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil

      next nil if trans_date.nil? && (trans_str.nil? || trans_str.empty?) && player_id.nil?

      {
        date:          trans_date,
        mlb_person_id: player_id,
        transaction:   trans_str
      }
    end
    .compact
  end

  private

  def parse_json(json)
    JSON.parse(json)
  rescue => e
    logger.info 'Failed to parse JSON.'
    logger.info json
    raise e
  end
end
