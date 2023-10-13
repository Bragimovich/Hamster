# frozen_string_literal: true

require_relative '../lib/football_box_score__keeper'
require_relative '../lib/football_box_score__scraper'
require_relative '../lib/football_box_score__parser'
require_relative '../lib/google_sheets'

require_relative '../models/limpar_prod_athletics'
require_relative '../models/limpar_prod_games'
require_relative '../models/football_box_score__stats'

class FootballManager < Hamster::Harvester

  GOOGLE_SHEET_ID = '1qEdmiRN8dHr14xu-eDpRb_ldFHNNiDPyhS9WgBhZJ0U'
  UUID = 1
  LINK = 2
  TYPE = 3
  DOWNLOADED = 4
  STORED = 5
  CONFIG_LOCATION = '/ini/Hamster/config.yml'

  def initialize
    super
    @keeper = FootballKeeper.new
    @parser = FootballParser.new
    @scraper = FootballScraper.new
    config     = YAML.load_file("#{ENV['HOME']}#{CONFIG_LOCATION}").with_indifferent_access
    service_key = config[:google_drive][:service_key]
    @google_service_account = StringIO.new(service_key.to_json)
  end

  def download
    send_to_slack message: "Project #0513 download started"
    @keeper.start_download
    @keeper.clear_store_folder

    download_spreadsheet_urls

    @keeper.finish_download
    send_to_slack message: "Project #0513 download finished"
  end

  def store
    send_to_slack message: "Project #0513 store started"
    @keeper.start_store

    store_spreadsheet_urls

    @keeper.finish
    send_to_slack message: "Project #0513 store finished"
  end

  private

  def download_spreadsheet_urls
    # binding.pry
    workbook = spreadsheet_by_id(GOOGLE_SHEET_ID, @google_service_account)
    workbook.worksheets.each {|w| download_worksheet_urls(w)}
  end

  def download_worksheet_urls(w)
    2.upto(w.max_rows) do |row|
      if w[row, DOWNLOADED] == 'FALSE'
        type = download_link(w[row, UUID], w[row, LINK])
        type && (w[row, TYPE] = type) && (w[row, DOWNLOADED] = 'TRUE') && w.save
      end
    rescue StandardError => e
      puts e, e.full_message
      send_to_slack message: "download_worksheet_urls:\n#{e.inspect}"
    end
  end

  def download_link(game_id, link)
    type = boxscore_type(link)
    return if type == 0
    game_page = @scraper.page_content(link) #game_page = @scraper.open_content(link)
    return if game_page.nil?
    @keeper.save_file(game_page, game_id)
    type
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

  def store_spreadsheet_urls
    files = peon.give_list.to_set
    workbook = spreadsheet_by_id(GOOGLE_SHEET_ID, @google_service_account)
    workbook.worksheets.each {|w| store_worksheet_urls(w, files)}
  end

  def store_worksheet_urls(w, files)
    2.upto(w.max_rows) do |row|
      next unless w[row, TYPE] == '1' && w[row, DOWNLOADED] == 'TRUE'
      file_name = "#{w[row, UUID]}.gz"
      next unless files.include? file_name
      game_details = game_info(w[row, UUID])
      store_game_page(file_name, game_details, w[row, LINK])
      (w[row, STORED] = 'TRUE') && w.save
    rescue StandardError => e
      puts e, e.full_message
      send_to_slack message: "store_worksheet_urls:\n#{e.inspect}"
    end
  end

  def game_info(game_id)
    LimparGame.find(game_id)
  end

  def store_game_page(file_name, game, game_url)
    parsed_page = parse_game_page(file_name)
    # store_box_score(parsed_page, game)
    store_passing_stats(parsed_page, game, game_url)
    store_rushing_stats(parsed_page, game, game_url)
    store_receiving(parsed_page, game, game_url)
    store_defensive(parsed_page, game, game_url)
  end

  def parse_game_page(file_name)
    game_page = @keeper.give_file(file_name)
    @parser.parse_page(game_page)
  end

  def store_box_score(parsed_page, game)
    box_score = @parser.parse_box_score(parsed_page)

    puts '======================================== boxscore ========================================'
    print_table box_score
    puts
  end

  def store_passing_stats(parsed_page, game, game_url)
    away_team_passing, home_team_passing = @parser.parse_passing_table(parsed_page)

    # puts '======================================== passing stats ========================================'
    # print_table away_team_passing
    # print_table home_team_passing
    # puts

    # FootballPlayerStats.column_names
    # array_of_stats.product([nil]).to_h
    away_passing_stats = @parser.parse_passing_stats(game.away_team_id, game.id, away_team_passing.drop(1), game_url)
    @keeper.store_all(away_passing_stats, FootballPlayerStats)

    home_passing_stats = @parser.parse_passing_stats(game.home_team_id, game.id, home_team_passing.drop(1), game_url)
    @keeper.store_all(home_passing_stats, FootballPlayerStats)
  end

  def store_rushing_stats(parsed_page, game, game_url)
    away_team_rushing, home_team_rushing = @parser.parse_rushing_table(parsed_page)

    # puts '======================================== rushing stats ========================================'
    # print_table away_team_rushing
    # print_table home_team_rushing
    # puts

    away_rushing_stats = @parser.parse_rushing_stats(game.away_team_id, game.id, away_team_rushing.drop(1), game_url)
    @keeper.store_all(away_rushing_stats, FootballPlayerStats)

    home_rushing_stats = @parser.parse_rushing_stats(game.home_team_id, game.id, home_team_rushing.drop(1), game_url)
    @keeper.store_all(home_rushing_stats, FootballPlayerStats)
  end

  def store_receiving(parsed_page, game, game_url)
    away_team_receiving, home_team_receiving = @parser.parse_receiving(parsed_page)

    # puts '======================================== receiving stats ========================================'
    # print_table away_team_receiving
    # print_table home_team_receiving
    # puts

    away_receiving_stats = @parser.parse_receiving_stats(game.away_team_id, game.id, away_team_receiving.drop(1), game_url)
    @keeper.store_all(away_receiving_stats, FootballPlayerStats)

    home_receiving_stats = @parser.parse_receiving_stats(game.home_team_id, game.id, home_team_receiving.drop(1), game_url)
    @keeper.store_all(home_receiving_stats, FootballPlayerStats)
  end

  def store_defensive(parsed_page, game, game_url)
    away_team_defensive, home_team_defensive = @parser.parse_defensive(parsed_page)

    # puts '======================================== defensive stats ========================================'
    # print_table away_team_defensive
    # print_table home_team_defensive
    # puts

    away_defensive_stats = @parser.parse_defensive_stats(game.away_team_id, game.id, away_team_defensive.drop(1), game_url)
    @keeper.store_all(away_defensive_stats, FootballPlayerStats)

    home_defensive_stats = @parser.parse_defensive_stats(game.home_team_id, game.id, home_team_defensive.drop(1), game_url)
    @keeper.store_all(home_defensive_stats, FootballPlayerStats)
  end

  def print_table(rows)
    rows.each do |r|
      row = r[0].ljust(20)
      r.drop(1).each { |item| row += item.ljust(8) }
      puts row
    end
    puts '================================================================================================='
  end

  def send_to_slack(message:, channel: 'U031HSK8TGF')
    Hamster.report(message: message, to: channel)
  end

end
