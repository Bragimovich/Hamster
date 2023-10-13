# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Scraper
  def initialize(options)
    super

    upload_aws_proc =
      Proc.new do |model_name, record_hash, file_key|
        upload_file_to_aws(model_name, record_hash, file_key)
      end

    @options = options
    @scraper = Scraper.new
    @parser  = Parser.new
    @aws_s3  = AwsS3.new(:hamster, :hamster)

    @keeper = Keeper.new(
      upload_aws_cb: upload_aws_proc,
      max_buffer_size: @options[:buffer]
    )
  end

  def run
    grab_hist   = @options.fetch(:history, false)
    limit_hist  = @options.fetch(:limit, false)
    grab_people = @options.fetch(:people, false)
    grab_trans  = @options.fetch(:transactions, false)
    grab_games  = @options.fetch(:games, false)
    skip_delete = @options.fetch(:skipdelete, false)
    grab_all    = !grab_people && !grab_trans && !grab_games
    grab_people = grab_all || grab_people
    grab_trans  = grab_all || grab_trans
    grab_games  = grab_all || grab_games

    @skip_teams = @options.fetch(:skipteams, '')
    @skip_teams = "" unless @skip_teams.instance_of?(String)
    @skip_teams = @skip_teams.split(',')

    run_for_teams(grab_people)
    logger.info "Teams : #{@teams_data.map { |t| "#{t[:slug]}(#{t[:id]})" }.join(',')}"
    run_for_people if grab_people

    start_year  = 2000
    start_month = 1
    if grab_hist
      if limit_hist
        prev_year_date = Date.current.prev_year
        start_year     = prev_year_date.year
        start_month    = prev_year_date.month
      end
    else
      prev_mon_date = Date.current.prev_month
      start_year    = prev_mon_date.year
      start_month   = prev_mon_date.month
    end

    run_for_transactions(start_year, start_month) if grab_trans
    run_for_games(start_year, start_month) if grab_games

    @keeper.flush
    @keeper.mark_deleted if !skip_delete && grab_people
    @keeper.finish
  rescue Exception => e
    cause_exc = e.cause || e
    unless cause_exc.is_a?(::Mysql2::Error) || cause_exc.is_a?(::ActiveRecord::ActiveRecordError)
      @keeper.flush rescue nil
    end
    raise e
  end

  private

  def run_for_games(start_year, start_month)
    completed_ids = []

    @teams_data.each do |team|
      next if @skip_teams.include?(team[:slug])
      logger.info "Games for team #{team[:slug]}"
      month_date = Date.new(start_year, start_month, 1)
      until_date  = Date.current.next_year
      while month_date <= until_date
        start_date   = month_date.strftime('%Y-%m-%d')
        end_date     = month_date.next_month.prev_day.strftime('%Y-%m-%d')
        schedule_url = "https://statsapi.mlb.com/api/v1/schedule?lang=en&sportId=11,12,13,14,15,16,5442,22&season=#{month_date.year}&startDate=#{start_date}&endDate=#{end_date}&teamId=#{team[:id]}&eventTypes=primary&scheduleTypes=games,events,xref"
        sched_json   = @scraper.get_content(schedule_url, :json)
        game_bases   = @parser.parse_schedules(sched_json)

        game_bases.each do |game_base|
          game_id = game_base[:id]
          next if completed_ids.include?(game_id)

          data_source_url = "https://www.milb.com/gameday/#{game_id}/final/box"
          # Get box score
          game_url  = "https://statsapi.mlb.com/api/v1.1/game/#{game_id}/feed/live?language=en"
          game_json = @scraper.get_content(game_url, :json, true)
          next if game_json.nil?

          game, line_score, batters, pitchers, addition = @parser.parse_game(game_json)

          unless game.nil?
            game[:home_team_score] = game_base[:home_score]
            game[:away_team_score] = game_base[:away_score]
            game[:makeup_date]     = game_base[:makeup_date]
            game[:add_info]        = game_base[:add_info]
            game[:day_game_number] = game_base[:day_game_number]
            game[:data_source_url] = data_source_url
            @keeper.save_data('MilbGame', game)
          end

          unless line_score.nil?
            line_score.each do |lscore|
              @keeper.save_data('MilbScoreByInnings', lscore)
            end
          end

          unless batters.nil?
            batters.each do |batter|
              batter[:data_source_url] = data_source_url
              @keeper.save_data('MilbBattersStat', batter)
            end
          end

          unless pitchers.nil?
            pitchers.each do |pitcher|
              pitcher[:data_source_url] = data_source_url
              @keeper.save_data('MilbPitchersStat', pitcher)
            end
          end

          unless addition.nil?
            addition[:data_source_url] = data_source_url
            @keeper.save_data('MilbGameAddInfo', addition)
          end

          completed_ids << game_id
        end

        month_date = month_date.next_month
      end

      @keeper.flush
    end
  end

  def run_for_people
    @teams_data.each do |team|
      next if @skip_teams.include?(team[:slug])
      logger.info "People in team #{team[:slug]}"
      # Get person list
      roster_html = @scraper.get_content("https://www.milb.com/#{team[:slug]}/roster")
      person_list = @parser.parse_person_list(roster_html)
      # Get every person details and stats
      person_list.each do |person|
        # Get person details
        person_html_url = "https://www.milb.com/player/#{person[:mlb_id]}"
        person_json_url = "https://statsapi.mlb.com/api/v1/people/#{person[:mlb_id]}?hydrate=currentTeam,education,social,draft&site=en"

        person_html = @scraper.get_content(person_html_url)
        person_json = @scraper.get_content(person_json_url, :json)
        person      = @parser.parse_person(person_html, person_json, person)

        person[:data_source_url] = person_html_url
        @keeper.save_data('MilbPerson', person)

        # Get person career stats
        stats_group = person[:full_position] == 'Pitcher' ? 'pitching' : 'hitting'
        stats_url   = "https://statsapi.mlb.com/api/v1/people/#{person[:mlb_id]}/stats?stats=yearByYear&gameType=R&leagueListId=milb_all&group=#{stats_group}&hydrate=team(league)&language=en"
        stats_json  = @scraper.get_content(stats_url, :json)
        stats       = @parser.parse_career_stats(stats_json)

        stats.each do |stat|
          stat[:data_source_url] = person_html_url
          @keeper.save_data('MilbCareerStat', stat)
        end
      end

      @keeper.flush('MilbPerson')
      @keeper.flush('MilbCareerStat')
    end
  end

  def run_for_teams(save_teams = true)
    # Get parent organizations
    orgs_json = @scraper.get_content('https://statsapi.mlb.com/api/v1/teams?sportIds=1&hydrate=division', :json)
    orgs_data = @parser.parse_organizations(orgs_json)
    # Get teams
    teams_html = @scraper.get_content('https://www.milb.com/about/teams/by-affiliate')
    @teams_data = @parser.parse_teams(teams_html, orgs_data)

    return unless save_teams

    # Save teams
    @teams_data.each do |team|
      @keeper.save_data(
        'MilbTeam',
        {
          mlb_id:          team[:id],
          team_name:       team[:name],
          team_abbr:       team[:abbr],
          level:           team[:level],
          mlb_team:        team[:parent],
          mlb_division:    team[:division],
          data_source_url: 'https://www.milb.com/about/teams/by-affiliate'
        }
      )
    end
    @keeper.flush('MilbTeam')
  end

  def run_for_transactions(start_year, start_month)
    @teams_data.each do |team|
      next if @skip_teams.include?(team[:slug])
      logger.info "Transactions for team #{team[:slug]}"
      team_slug  = team[:slug]
      month_date = Date.new(start_year, start_month, 1)
      curr_date  = Date.current
      while month_date <= curr_date
        trans_url  = "https://www.milb.com/#{team_slug}/roster/transactions/#{month_date.year}-#{month_date.month.to_s.rjust(2, '0')}"
        trans_html = @scraper.get_content(trans_url)

        transactions = @parser.parse_transactions(trans_html)
        transactions.each do |trans|
          trans[:mlb_team_id]     = team[:id]
          trans[:data_source_url] = trans_url
          @keeper.save_data('MilbTeamTransaction', trans)
        end

        month_date = month_date.next_month
      end

      @keeper.flush('MilbTeamTransaction')
    end
  end

  def upload_file_to_aws(model_name, record_hash, file_key)
    return nil unless model_name == 'MilbPerson' && file_key.to_s == 'org_img_url'
    return nil if record_hash.nil? || record_hash[file_key].nil?

    dl_result = @scraper.get_content(record_hash[file_key], :image)
    if dl_result.nil?
      nil
    else
      s3_path = "us_sports_milb/player_photos/#{record_hash[:mlb_id]}.jpg"
      @aws_s3.put_file(dl_result, s3_path)
    end
  end
end
