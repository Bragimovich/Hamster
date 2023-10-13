# frozen_string_literal: true

class FootballParser < Hamster::Parser

  def parse_page(page)
    Nokogiri::HTML(page)
  end

  def parse_csv(file)
    url = {}
    CSV.foreach(file, :headers => true) {|row| url.store(row['Limpar Game UUID'], row['Link to Box Score'])}
    url
  end

  def parse_worksheet(w)
    url = {}
    w.rows(1).each {|row| url.store(row[0], row[1]) unless row[2].empty?}
    url
  end

  def parse_box_score(html)
    box_score = html.at('main figcaption table')
    header = box_score.at('thead').css('th')
    header = [header[0].text.strip] + header.drop(1).map { |h| h.at('.hide-on-medium').text.strip }
    rows = box_score.at('tbody').css('tr')
    teams = rows.map do |r|
      stats = r.css('td')
      team_names = stats[0].css('span').map { |t| t.text.strip }.reject(&:empty?).last
      points = stats.drop(1).map { |s| s.text.strip }
      [team_names] + points
    end
    [header, *teams]
  end

  def parse_passing_table(html)
    passing_stats = html.css('#individual-passing table')
    # parse_tables(passing_stats)
    passing_stats.map { |t| parse_table(t) }
  end

  def parse_passing_stats(team_id, game_id, rows, game_url)
    rows.map do |player|
      stats = {
        team_id:          team_id,
        game_id:          game_id,
        player:           player[0],
        passing_cmp:      player[1],
        passing_att:      player[2],
        passing_yds:      player[3],
        passing_td:       player[4],
        passing_int:      player[5],
        passing_long:     player[6],
        passing_sack:     player[7],
        data_source_url:  game_url
      }
    end
  end

  def parse_rushing_table(html)
    rushing_stats = html.css('#individual-rushing table')
    # parse_tables(rushing_stats)
    rushing_stats.map { |t| parse_table(t) }
  end

  def parse_rushing_stats(team_id, game_id, rows, game_url)
    rows.map do |player|
      stats = {
        team_id:          team_id,
        game_id:          game_id,
        player:           player[0],
        rushing_att:      player[1],
        rushing_gain:     player[2],
        rushing_loss:     player[3],
        rushing_net:      player[4],
        rushing_td:       player[5],
        rushing_lg:       player[6],
        rushing_avg:      player[7],
        data_source_url:  game_url
      }
    end
  end

  def parse_receiving(html)
    receiving_stats = html.css('#individual-receiving table')
    # parse_tables(receiving_stats)
    receiving_stats.map { |t| parse_table(t) }
  end

  def parse_receiving_stats(team_id, game_id, rows, game_url)
    rows.map do |player|
      stats = {
        team_id:          team_id,
        game_id:          game_id,
        player:           player[0],
        receiving_rec:    player[1],
        receiving_yds:    player[2],
        receiving_td:     player[3],
        receiving_long:   player[4],
        data_source_url:  game_url
      }
    end
  end

  def parse_defensive(html)
    defensive_away_stats = html.css('#defense-away table')
    away_team = parse_table(defensive_away_stats)

    defensive_home_stats = html.css('#defense-home table')
    home_team = parse_table(defensive_home_stats)

    [away_team, home_team]
  end

  def parse_defensive_stats(team_id, game_id, rows, game_url)
    rows.map do |player|
      stats = {
        team_id:            team_id,
        game_id:            game_id,
        player:             player[0],
        defensive_solo:     player[1],
        defensive_ast:      player[2],
        defensive_tot:      player[3],
        defensive_tfl_yds:  player[4],
        defensive_sack_yds: player[5],
        defensive_ff:       player[6],
        defensive_f_r_yds:  player[7],
        defensive_int:      player[8],
        defensive_br_up:    player[9],
        defensive_blkd:     player[10],
        defensive_q_h:      player[11],
        data_source_url:    game_url
      }
    end
  end

  def parse_tables(stats)
    header = stats.first.css('thead th').map { |x| x.text.strip }
    teams = stats.map do |t|
      t.css('tbody tr').map { |p| p.css('td').map { |s| s.text.strip } }
    end
    [header, *teams]
  end

  def parse_table(stats)
    header = stats.css('thead th').map { |x| x.text.strip }
    players = stats.css('tbody tr').map { |p| p.css('td').map { |s| s.text.strip } }
    players.pop if players.last.first.downcase == "team"
    [header, *players]
  end

end
