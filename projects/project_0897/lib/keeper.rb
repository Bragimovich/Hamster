# frozen_string_literal: true

require_relative '../models/football_conferences'
require_relative '../models/football_runs'
require_relative '../models/football_standings'
require_relative '../models/football_teams'
require_relative '../models/school_alias'
require_relative '../models/schools'

class Keeper < Hamster::Harvester
  CONFERENCE_HASH = [ 'conf_name', 'season', 'data_source_url' ]
  TEAM_HASH = [ 'team_name', 'data_source_url' ]

  def initialize
    @run_object = safe_operation(FootballRun) { |model| RunId.new(model) }
    @run_id = safe_operation(FootballRun) { @run_object.run_id }
  end

  def insert_teams_and_conference_data(data_array)
    data_array.each do |data_hash|
      conference_hash = get_correct_hash(data_hash, CONFERENCE_HASH, "conf_name")
      team_hash = get_correct_hash(data_hash, TEAM_HASH, "team_name")
      @schools = School.all
      @school_aliases = SchoolAlias.all
      
      logger.info "*************** Inserting Conference #{conference_hash["name"]} ***************"
      conference_hash = genrate_md5_and_run_ids(conference_hash)
      FootballConference.insert(conference_hash)
      logger.info "*************** Conference #{conference_hash["name"]} Inserted ***************"

      logger.info "*************** Inserting Team #{team_hash["name"]} ***************"
      conference = FootballConference.find_by(name: conference_hash["name"], deleted: false)
      logger.info "*************** #{conference.nil? ? "Conference Not Found" : "Got Conference"} ***************"
      team_hash["conference_id"] = conference.nil? ? nil : conference.id
      team_clean_name = team_hash["name"].gsub(/\[[^\]]+\]/, "").gsub(/\,\s*\S*/, "").squish
      school = @schools.find_by(name: team_clean_name, deleted: false)
      if school.nil?
        school_alias = @school_aliases.find_by(aliase_name: team_clean_name, deleted: false)
        if school_alias.nil?
          logger.info "*************** School Not Found #{team_hash["name"]} ***************"
        else
          team_hash["school_id"] = school_alias.school_id
          logger.info "*************** Got School by Aliases #{school_alias.school_id} ***************"
        end
      else
        team_hash["school_id"] = school.id
        logger.info "*************** Got School #{school.id} ***************"
      end
      team_hash = genrate_md5_and_run_ids(team_hash)
      FootballTeam.insert(team_hash)
      logger.info "*************** Team #{team_hash["name"]} Inserted ***************"
      
    end
  end
  
  def  insert_standings_data(data_array)
    data_array.each do |data_hash|
      logger.info "*************** Inserting Standing  Data ***************"
      standing_hash = {}
      home_team = FootballTeam.find_by(name: data_hash["ex_team_name"], deleted: false)
      road_team = FootballTeam.find_by(name: data_hash["ex_road_team_name"], deleted: false)
      standing_hash["home_team_id"] = home_team != nil ? home_team.id : nil 
      standing_hash["home_conference_id"] = home_team != nil ? home_team.conference_id : nil
      standing_hash["road_team_id"] = road_team != nil ? road_team.id : nil
      standing_hash["road_conference_id"] = road_team != nil ? road_team.conference_id : nil
      standing_hash["game_date"] = data_hash["game_date"]
      standing_hash["game_time"] = data_hash["game_time"]
      standing_hash["data_source_url"] = data_hash["data_source_url"]
      standing_hash = genrate_md5_and_run_ids(standing_hash)
      FootballStanding.insert(standing_hash)
      logger.info "*************** Team STANDINGs #{home_team.name} Inserted ***************"
    end
  end

  def finish
    safe_operation(FootballRun) { @run_object.finish }
  end
  
  attr_reader :run_id

  private

  def genrate_md5_and_run_ids(data_hash)
    data_hash["md5_hash"] = Digest::MD5.hexdigest data_hash.values * ""
    data_hash["run_id"] = run_id
    data_hash
  end

  def get_correct_hash(data_hash, hash_keys, rename_key)
    data_hash.select { |key, _value| hash_keys.include?(key) }.to_h.transform_keys { |key| key == rename_key ? "name" : key }
  end

  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.error "#{e.class}"
        logger.error "Reconnect!"
        sleep 100
        model.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end
    retry
    end
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end

end
