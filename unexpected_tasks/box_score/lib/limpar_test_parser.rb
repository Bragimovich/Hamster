# frozen_string_literal: true

require_relative '../models/limpar_prod_athletics'
require_relative '../models/limpar_prod_games'
require_relative '../models/limpar_test_box_scores'
require_relative '../models/limpar_test_runs'
require 'pp'
require 'pry'
require 'csv'

class LimparParser < Hamster::Scraper

  CSV_PATH = './unexpected_tasks/box_score/csv/*'

  def initialize
    # super
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @run_id = nil
    @statistics = {}
    LimparStatistic.all.each { |s| @statistics[s.abbreviation] = s.id }
  end

  def start
    Hamster.report(to: 'Alim Lumanov', message: "Box scores parsing started", use: :telegram)
    mark_as_started

    parse
    p 'parsing finished'

    mark_as_finished
    Hamster.report(to: 'Alim Lumanov', message: "Box scores parsing finished", use: :telegram)
  rescue => e
    p 'inside start rescue'
    p e
    # Hamster.report(to: 'Alim Lumanov', message: "Box scores start: Error - \n#{e}", use: :telegram)
  end

  private

  def parse
    files = Dir['./unexpected_tasks/box_score/csv/*']
    files.each do |f|
      CSV.foreach(f, :headers => true) do |row|
        p row
        parse_link(row['game_id'], row['box_score']) if row['box_score'] =~ /sports\/[a-z]+\/stats\/\d+\/(?:[a-z]+[-]?)+\/boxscore/
      rescue StandardError => e
        p e
        p e.full_message
        # Hamster.report(to: 'Alim Lumanov', message: "Box scores parse_link: Error - \n#{e}")
      end
    end
  end

  def parse_link(game_id, link)
    game = LimparGame.find_by(id: game_id).as_json
    return if game.nil?
    home_team = LimparTeam.find_by(id: game['home_team_id'])
    # away_team = LimparTeam.find_by(id: game['away_team_id'])
    # athletic_sport = LimparAthleticSport.find_by(id: home_team['athletic_sport_id'])

    sport_id = home_team['athletic_sport_id']
    page = connect_to(link, proxy_filter: @filter, ssl_verify: false)&.body
    html = Nokogiri::HTML(page)
    team_id = [nil, nil]
    parse_line_score(game, team_id, sport_id, html)
    parse_box_score(game, team_id, html)
    # parse_composite_stats(html)
  rescue StandardError => e
    p e
    p e.full_message
    # Hamster.report(to: 'Alim Lumanov', message: "Box scores download_index: Error - \n#{e}")
  end

  def parse_line_score(game, team_id, sport_id, html)
    headers, away_team, home_team, team_id[0], team_id[1] = match_teams(game, html)
    # binding.pry
    sport_matches, additional_fields = {}, {}
    LimparSportMatch.where(athletic_sport_id: sport_id, deleted_at: nil).each { |m| sport_matches[m.match] = m.id }
    LimparAthleticSportAdditionalField.where(athletic_sport_id: sport_id, deleted_at: nil).each { |f| additional_fields[f.name] = f.id }
    matches, additionals = [], []

    headers.zip(away_team, home_team).each do |header, away, home|
      if sport_matches.key? header
        match = {
          :game_id => game['id'],
          :sport_match_id => sport_matches[header],
          :away_team_points => away,
          :home_team_points => home
        }
        matches.push match
      elsif additional_fields.key? header
        field = {
          :game_id => game['id'],
          :athletic_sport_additional_field_id => additional_fields[header],
          :away_team_value => away,
          :home_team_value => home
        }
        additionals.push field
      end
    end
    LimparGameMatch.insert_all(matches) unless matches.empty?
    LimparGameBoxScoreAdditional.insert_all(additionals) unless additionals.empty?

    parse_game_details(html, game, additionals, additional_fields['R'])
  end

  def match_teams(game, html)
    caption = html.at('main figcaption')
    body = caption.at('table tbody').css('tr')
    header = caption.at('table thead').css('th')
    team_1 = [body[0].at('th .hide-on-large-down')] + caption.css('table tbody tr')[0].css('td')
    team_2 = [body[1].at('th .hide-on-large-down')] + caption.css('table tbody tr')[1].css('td')
    header = header.map { |x| x.text.strip }
    team_1 = team_1.map { |x| x.text.strip }
    team_2 = team_2.map { |x| x.text.strip }

    home_team = LimparTeam.find_by(id: game['home_team_id'])
    away_team = LimparTeam.find_by(id: game['away_team_id'])
    home_team_name = home_team.name.downcase
    away_team_name = away_team.name.downcase
    team_1_words = team_1[0].downcase.scan(/\w+/)
    team_2_words = team_2[0].downcase.scan(/\w+/)
    if team_1_words.all? { |word| away_team_name.include? word } && team_2_words.all? { |word| home_team_name.include? word }
      return header, team_1, team_2, game['away_team_id'], game['home_team_id']
    elsif team_2_words.all? { |word| away_team_name.include? word } && team_1_words.all? { |word| home_team_name.include? word }
      return header, team_2, team_1, game['home_team_id'], game['away_team_id']
    elsif team_1_words.all? { |word| away_team_name.include? word } || team_2_words.all? { |word| home_team_name.include? word }
      return header, team_1, team_2, game['away_team_id'], game['home_team_id']
    elsif team_2_words.all? { |word| away_team_name.include? word } || team_1_words.all? { |word| home_team_name.include? word }
      return header, team_2, team_1, game['home_team_id'], game['away_team_id']
    # elsif team_1_words.any? { |word| away_team_name.include? word } || team_2_words.any? { |word| home_team_name.include? word }
    #   return header, team_1, team_2, game['away_team_id'], game['home_team_id']
    # elsif team_2_words.any? { |word| away_team_name.include? word } || team_1_words.any? { |word| home_team_name.include? word }
    #   return header, team_2, team_1, game['home_team_id'], game['away_team_id']
    else
      p "#{away_team_name} => #{team_1[0]}; #{home_team_name} => #{team_2[0]}"
      binding.pry
      return header, team_1, team_2, game['away_team_id'], game['home_team_id']

      raise StandardError.new "no full match found"
      return header, nil, nil
    end
  end

  def parse_game_details(html, game, adds, key)
    details = html.at('main aside')
    items = details.css('dl dt')
    game_details = {}
    items.each do |item|
      game_details[item.text.strip] = item.next_element.text.strip
    end
    Pry::ColorPrinter.pp game_details

    adds.each do |a|
      if a[:athletic_sport_additional_field_id] == key
        game['home_team_points'] = a[:home_team_value]
        game['away_team_points'] = a[:away_team_value]
        LimparGameFilled.insert game
        break
      end
    end
  end

  def parse_box_score(game, team_id, html)
    teams = html.css('main section#box-score section[aria-label="Team Individual Statistics"] table')
    teams.zip(team_id).each do |t, id|
      heads = t.at('thead tr').css('th') # descs = heads.map { |h| h.attr('title')&.strip || h.text.strip }
      titles = heads.map { |h| h.text.strip }
      rows = t.at('tbody').css('tr')
      team_roster = LimparAthleticRoster
                      .where(team_id: id, athletic_season_id: game['athletic_season_id'])
                      .map { |r| [r.id, "#{r.first_name} #{r.last_name}".downcase] }
      players = []
      rows.each do |row|
        vals = row.elements.map { |e| e.name == 'td' ? e.text.strip : e.children.last.text.strip }
        # vals.each_with_index { |v, i| print "#{v}".ljust(titles[i].size + 1) }
        players.concat(parse_player_stats(team_roster, titles, vals, game['id']))
      end
      LimparBoxScore.insert_all players unless players.empty?
    end
  end

  def parse_player_stats(players, heads, vals, game_id)
    player_roster_id = nil
    player_name_words = vals[1].downcase.scan(/\w+/)
    players.each do |p|
      if player_name_words.all? { |word| p[1].include? word }
        player_roster_id = p[0]
        break
      end
    end
    # binding.pry
    all_stats = []
    heads.drop(2).each_with_index do |t, i|
      stat = {
        :value => vals[i + 2],
        :athletic_roster_id => player_roster_id || vals[1],
        :statistic_id => @statistics[t],
        :game_id => game_id
      }
      all_stats.push stat
    end
    all_stats
  end

  # def parse_composite_stats(html)
  #   teams = html.css('main section#composite-stats table')
  #   teams.each do |t|
  #     heads = t.at('thead tr').css('th')
  #     descs = heads.map { |h| h.attr('title')&.strip || h.text.strip }
  #     titles = heads.map { |h| h.text.strip }
  #     p descs
  #     p titles
  #     rows = t.at('tbody').css('tr')
  #     rows.each do |row|
  #       vals = row.elements.map { |e| e.name == 'td' ? e.text.strip : e.children.last.text.strip }
  #       p vals
  #     end
  #   end
  # end

  def insert_all(model, data)
    model.insert_all(data) unless data.empty?
  end

  def mark_as_started
    LimparTestRun.create
    @run_id = LimparTestRun.last.id
    LimparTestRun.find(@run_id).update(status: 'parse started')
  end

  def connect_to(*arguments, &block)
    response = nil
    3.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end
    response
  end

  def mark_as_finished
    LimparTestRun.find(@run_id).update(status: 'parse finished')
  end

end

