# frozen_string_literal: true

require_relative '../lib/football_box_score__keeper'
require_relative '../lib/football_box_score__scraper'
require_relative '../lib/football_box_score__parser'

require_relative '../models/limpar_prod_athletics'
require_relative '../models/limpar_prod_games'
# require_relative '../models/limpar_test_box_scores'

class FootballManager < Hamster::Harvester

  LINKS = %w[
    https://iwuwildcats.com/sports/football/stats/2022/valparaiso-university/boxscore/10196
    https://faulknereagles.com/sports/football/stats/2022/reinhardt-university/boxscore/6813
    https://saintaugfalcons.com/sports/football/stats/2022/tusculum-university/boxscore/3590
    https://csssaints.com/sports/football/stats/2022/sewanee/boxscore/14582
    https://ouazspirit.com/sports/football/stats/2022/lyon/boxscore/4173
    https://goetbutigers.com/sports/football/stats/2022/-19-uw-oshkosh/boxscore/6964
    https://www.gounionbulldogs.com/SIDHelp/fullBoxScores/20/19/15047
    https://www.sauknights.com/sport/football/2022-23/box-scores/5864/lindsey-wilson-college-vs-st-andrews
    https://www.acufirestorm.com/SIDHelp/fullBoxScores/20/5/6136
    https://tlubulldogs.com/sports/fball/2022-23/boxscores/20220903_v6s5.xml
    https://www.bentleyfalcons.com/sports/fball/2022-23/boxscores/20220902_n90t.xml
    https://www.kcuknights.com/sports/fball/2022-23/boxscores/20220825_d0y8.xml
    https://www.woosterathletics.com/sports/fball/2022-23/boxscores/20220903_bzfa.xml
    https://www.wubearcats.com/sports/fball/2022-23/boxscores/20220903_zdo9.xml
    https://westfieldstateowls.com/sports/fball/2022-23/boxscores/20220902_iwb3.xml
  ]

  def initialize
    super
    @keeper = FootballKeeper.new
    @parser = FootballParser.new
    @scraper = FootballScraper.new
    @run_id = @keeper.run_id
    @athletic_sport_id = '101f848f-7e03-43ee-aa55-439d65e52a52'
    @football_stats = sport_statistics
    @all_stats = all_stats
    @passing_range = 0..4
    @rushing_range = 5..10
  end

  def download
    Hamster.report(to: 'Alim Lumanov', message: "Project #0513 download started")
    @keeper.start_download
    @keeper.clear_store_folder

    # download_links(LINKS)
    download_from_csv

    @keeper.finish_download
    Hamster.report(to: 'Alim Lumanov', message: "Project #0513 download finished")
  end

  def store
    Hamster.report(to: 'Alim Lumanov', message: "Project #0513 store started")
    # @keeper.start_store

    files = peon.give_list.sort
    files.each do |f|
      type, game_id = f.sub('.gz', '').split('_')
      next unless type == '1'
      game = LimparGame.find(game_id)
      store_game_page(game, f)

      binding.pry
      # res = match_teams(game_id, tables[0])
      # rel = LimparBoxScore.where(game_id: game_id)
      # LimparSportStatistic.where(athletic_sport_id: '101f848f-7e03-43ee-aa55-439d65e52a52').pluck(:statistic_id)
      # LimparSportStatistic.where(athletic_sport_id: ATHLETIC_SPORT_ID, deleted_at: nil).pluck(:order, :statistic_id).sort
      # LimparSportMatch.where(athletic_sport_id: ATHLETIC_SPORT_ID).pluck(:match, :id).sort_by(&:first)
    end

    # @keeper.store_game(box_score, passing, rushing, receiving, defensive)
    @keeper.finish
    Hamster.report(to: 'Alim Lumanov', message: "Project #0513 store finished")
  end

  private

  def download_links(urls)
    urls.each_with_index do |link, idx|
      type = boxscore_type(link)
      next if type == 0
      # game_page = @scraper.page_content(link)
      game_page = @scraper.open_content(link)
      next if game_page.nil?
      file_name = "#{idx.to_s.rjust(3, "0")}_#{type}"
      @keeper.save_file(game_page, file_name)
      # binding.pry
    end
  end

  def download_from_csv
    files = Dir['./projects/project_0513/csv/*']
    files.each do |f|
      CSV.foreach(f, :headers => true) do |row|
        p row
        download_link(row['Limpar Game UUID'], row['Link to Box Score'])
      rescue StandardError => e
        p e
        p e.full_message
        # Hamster.report(to: 'Alim Lumanov', message: "Box scores download_from_csv:\n#{e}")
      end
    end
  end

  def download_link(uuid, link)
    type = boxscore_type(link)
    return if type == 0
    game_page = @scraper.page_content(link)
    # game_page = @scraper.open_content(link)
    return if game_page.nil?
    file_name = "#{type}_#{uuid}"
    @keeper.save_file(game_page, file_name)
    # binding.pry
  end

  def boxscore_type(link)
    case link
    when /sports\/football\/stats\/\d+\/[-\w]+\/boxscore/ then 1
    when /SIDHelp\/fullBoxScores/ then 3
    when /sport\/football\/2022-23\/box-scores/ then 3
    when /sports\/fball\/2022-23\/boxscores/ then 4
    else 0
    end
  end

  def store_game_page(game, file_name)
    parsed_page = parse_game_page(file_name)

    away_team_roster = team_roster(game.away_team_id, game.athletic_season_id)
    home_team_roster = team_roster(game.home_team_id, game.athletic_season_id)

    store_box_score(parsed_page, game.id)
    store_passing(parsed_page, away_team_roster, home_team_roster, game.id)
    store_rushing(parsed_page, away_team_roster, home_team_roster, game.id)

    # rushing = @parser.parse_rushing(parsed_page)
    # receiving = @parser.parse_receiving(parsed_page)
    # defensive = @parser.parse_defensive(parsed_page)

    # return game_id, box_score, passing, rushing, receiving, defensive
  end

  def parse_game_page(file_name)
    game_page = @keeper.give_file(file_name)
    @parser.parse_page(game_page)
  end

  def team_roster(away_team_id, athletic_season_id)
    LimparAthleticRoster.where(team_id: away_team_id, athletic_season_id: athletic_season_id)
                        .select(:id, :first_name, :last_name)
  end

  def sport_statistics
    LimparSportStatistic.where(athletic_sport_id: @athletic_sport_id, deleted_at: nil)
                        .order(:order)
                        .pluck(:statistic_id)
  end

  def all_stats
    LimparStatistic.pluck(:id, :description).to_h
  end

  def store_box_score(parsed_page, game_id)
    sport_match_id = LimparSportMatch.where(athletic_sport_id: @athletic_sport_id).pluck(:match, :id).sort_by(&:first)
    box_score = @parser.parse_box_score(parsed_page)
    box_score.transpose[1..-2].zip(sport_match_id).each do |b, s|
      puts "#{game_id}, #{s[1]}, #{b[1]}, #{b[2]}"
    end
    binding.pry
  end

  def store_passing(parsed_page, away_team_roster, home_team_roster, game_id)
    away_team_passing, home_team_passing = @parser.parse_passing(parsed_page)
    binding.pry
    stats_name = away_team_passing[0].drop(1)
    away_team_passing.drop(1).map do |player_name, *stats|
      athletic_roster_id = player_id(away_team_roster, player_name)
      @passing_range.zip(stats).each do |i, s|
        p "#{athletic_roster_id}, #{game_id}, #{stats_name[i]}, #{@football_stats[i]}. #{@all_stats[@football_stats[i]]}, #{s}"
      end
      p '=============================================================================================================='
    end
    binding.pry
    home_team_passing.drop(1).map do |player_name, *stats|
      athletic_roster_id = player_id(home_team_roster, player_name)
      @passing_range.zip(stats).each do |i, s|
        p "#{athletic_roster_id}, #{game_id}, #{stats_name[i]}, #{@football_stats[i]}. #{@all_stats[@football_stats[i]]}, #{s}"
      end
      p '=============================================================================================================='
    end
    binding.pry
  end

  def store_rushing(parsed_page, away_team_roster, home_team_roster, game_id)
    away_team_rushing, home_team_rushing = @parser.parse_rushing(parsed_page)
    stats_name = away_team_rushing[0].drop(1)
    diff = 5
    binding.pry
    away_team_rushing.drop(1).map do |player_name, *stats|
      athletic_roster_id = player_id(away_team_roster, player_name)
      @rushing_range.zip(stats).each do |i, s|
        p "#{athletic_roster_id}, #{game_id}, #{stats_name[i - diff]}, #{@football_stats[i]}. #{@all_stats[@football_stats[i]]}, #{s}"
      end
      p '=============================================================================================================='
    end
    binding.pry
    home_team_rushing.drop(1).map do |player_name, *stats|
      athletic_roster_id = player_id(home_team_roster, player_name)
      @rushing_range.zip(stats).each do |i, s|
        p "#{athletic_roster_id}, #{game_id}, #{stats_name[i - diff]}, #{@football_stats[i]}. #{@all_stats[@football_stats[i]]}, #{s}"
      end
      p '=============================================================================================================='
    end
    binding.pry
  end

  def player_id(team_roster, player_name)
    player_roster_id = nil
    team_roster.each do |player|
      if player_name.include?(player.first_name) && player_name.include?(player.last_name)
        player_roster_id = player.id
        break
      end
    end
    player_roster_id || player_name
  end

  def match_stats()
    return if game.nil?
    home_team = LimparTeam.find_by(id: game['home_team_id'])
    # away_team = LimparTeam.find_by(id: game['away_team_id'])
    # athletic_sport = LimparAthleticSport.find_by(id: home_team['athletic_sport_id'])
    sport_id = home_team['athletic_sport_id']

    res = match_teams(game, box_score)
    binding.pry
    sport_matches = {}
    LimparSportMatch.where(athletic_sport_id: sport_id, deleted_at: nil).each { |m| sport_matches[m.match] = m.id }
    matches = []
    binding.pry
  end

  def match_teams(game_id, box_score)
    team_1 = box_score[1][0]
    team_2 = box_score[2][0]
    game = LimparGame.find_by(id: game_id).as_json
    home_team = LimparTeam.find_by(id: game['home_team_id'])
    away_team = LimparTeam.find_by(id: game['away_team_id'])
    home_team_name = home_team.name.downcase
    away_team_name = away_team.name.downcase
    team_1_words = team_1[1].downcase.scan(/\w+/)
    team_2_words = team_2[1].downcase.scan(/\w+/)

    if team_1_words.all? { |word| away_team_name.include? word } && team_2_words.all? { |word| home_team_name.include? word }
      return [team_1, team_2, game['away_team_id'], game['home_team_id'], '100%']
    elsif team_2_words.all? { |word| away_team_name.include? word } && team_1_words.all? { |word| home_team_name.include? word }
      return [team_2, team_1, game['home_team_id'], game['away_team_id'], '100%']
    elsif team_1_words.all? { |word| away_team_name.include? word } || team_2_words.all? { |word| home_team_name.include? word }
      return [team_1, team_2, game['away_team_id'], game['home_team_id'], '60%']
    elsif team_2_words.all? { |word| away_team_name.include? word } || team_1_words.all? { |word| home_team_name.include? word }
      return [team_2, team_1, game['home_team_id'], game['away_team_id'], '60%']
    elsif team_1_words.any? { |word| away_team_name.include? word } && team_2_words.any? { |word| home_team_name.include? word }
      return [team_1, team_2, game['away_team_id'], game['home_team_id'], '40%']
    elsif team_2_words.any? { |word| away_team_name.include? word } && team_1_words.any? { |word| home_team_name.include? word }
      return [team_2, team_1, game['home_team_id'], game['away_team_id'], '40%']
    elsif team_1_words.any? { |word| away_team_name.include? word } || team_2_words.any? { |word| home_team_name.include? word }
      return [team_1, team_2, game['away_team_id'], game['home_team_id'], '20%']
    elsif team_2_words.any? { |word| away_team_name.include? word } || team_1_words.any? { |word| home_team_name.include? word }
      return [team_2, team_1, game['home_team_id'], game['away_team_id'], '20%']
    else
      p "#{away_team_name} => #{team_1[1]}; #{home_team_name} => #{team_2[1]}"
      binding.pry
      raise StandardError.new "no any match found"
      return nil, nil, nil, nil, nil
    end
  end

end
