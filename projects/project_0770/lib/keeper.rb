# frozen_string_literal: true

require_relative '../models/milb_batters_stat'
require_relative '../models/milb_career_stat'
require_relative '../models/milb_game_add_info'
require_relative '../models/milb_game'
require_relative '../models/milb_person'
require_relative '../models/milb_pitchers_stat'
require_relative '../models/milb_roster'
require_relative '../models/milb_run'
require_relative '../models/milb_score_by_innings'
require_relative '../models/milb_team_transaction'
require_relative '../models/milb_team'

class Keeper
  DEFAULT_MAX_BUFFER_SIZE = 100

  MD5_COLUMNS = {
    'MilbBattersStat'     => %i[mlb_game_id roster_hash],
    'MilbCareerStat'      => %i[roster_hash],
    'MilbGameAddInfo'     => %i[mlb_game_id],
    'MilbGame'            => %i[mlb_id],
    'MilbPitchersStat'    => %i[mlb_game_id roster_hash],
    'MilbRoster'          => %i[mlb_team_id mlb_person_id season],
    'MilbScoreByInnings'  => %i[mlb_game_id mlb_team_id score_key],
    'MilbTeamTransaction' => %i[date mlb_team_id mlb_person_id transaction],
    'MilbTeam'            => %i[mlb_id team_name team_abbr level mlb_team mlb_division data_source_url],
    'MilbPerson'          => %i[
      mlb_id current_team_id full_name alias first_name middle_name last_name full_position number
      status mlb_40_man b_t height weight birth_date country city state mlb_debut college_name
      college_city college_state high_school_name high_school_city high_school_state instagram
      twitter draft_year draft_team draft_round draft_overall_pick bio_info org_img_url data_source_url
    ]
  }

  RUNID_MODELS    = %w[MilbTeam MilbPerson]
  UPLOAD_AWS_COLS = [['MilbPerson', :org_img_url, :aws_img_url]]

  def initialize(options = {})
    @max_buf_size  = options[:max_buffer_size] || DEFAULT_MAX_BUFFER_SIZE
    @max_buf_size  = 50 if @max_buf_size < 50
    @upload_aws_cb = options[:upload_aws_cb]
    @run_object    = RunId.new(MilbRun)
    @run_id        = @run_object.run_id

    @md5_builders =
      MD5_COLUMNS.each_with_object({}) do |(klass, cols), hash|
        hash[klass] = MD5Hash.new(columns: cols)
      end

    @buffer = {
      'MilbTeam'            => [],
      'MilbPerson'          => [],
      'MilbRoster'          => [],
      'MilbCareerStat'      => [],
      'MilbTeamTransaction' => [],
      'MilbGame'            => [],
      'MilbScoreByInnings'  => [],
      'MilbBattersStat'     => [],
      'MilbPitchersStat'    => [],
      'MilbGameAddInfo'     => []
    }
  end

  def finish
    @run_object.finish
  end

  def flush(model_class = nil)
    model_clazz = model_class.nil? ? @buffer.keys : [model_class]
    model_clazz.each do |klass|
      klass      = klass.constantize if klass.is_a?(String)
      model_name = klass.name
      next if @buffer[model_name].nil? || @buffer[model_name].count.zero?

      db_query_cols = []
      db_query_cols << :run_id if RUNID_MODELS.include?(model_name)

      aws_cols = UPLOAD_AWS_COLS.select { |ac| ac[0] == model_name }
      aws_cols.each { |ac| db_query_cols << ac[1] << ac[2] }

      unless db_query_cols.size.zero?
        db_values =
          Hash[
            klass.where(
              md5_hash: @buffer[model_name].map { |h| h[:md5_hash] }
            )
            .map { |r| [r.md5_hash, db_query_cols.map { |col| r[col] }] }
          ]

        @buffer[model_name].each do |hash|
          values = db_values[hash[:md5_hash]] || []
          hash[:run_id] = values.shift || @run_id if RUNID_MODELS.include?(model_name)
          hash[:updated_at] = Time.now

          aws_cols.each do |ac|
            org_url = values.shift
            aws_url = values.shift
            if !org_url.nil? && !aws_url.nil? && org_url == hash[ac[1]]
              hash[ac[2]] = aws_url
            elsif !hash[ac[1]].nil? && !@upload_aws_cb.nil?
              hash[ac[2]] = @upload_aws_cb.call(model_name, hash, ac[1])
            else
              hash[ac[2]] = nil
            end
          end
        end
      end

      klass.upsert_all(@buffer[model_name])
      Hamster.close_connection(klass)
      @buffer[model_name] = []
    end
  end

  def mark_deleted
    RUNID_MODELS.each do |model_name|
      model_class  = model_name.constantize
      model_class.where.not(touched_run_id: @run_id).update_all(deleted: true)
      model_class.where(touched_run_id: @run_id).update_all(deleted: false)
      Hamster.close_connection(model_class)
    end
  end

  def save_data(model_class, hash)
    model_class = model_class.constantize if model_class.is_a?(String)
    model_name  = model_class.name
    return if @buffer[model_name].nil?

    normalize_method = "normalize_#{model_name.underscore}".to_sym
    hash = send(normalize_method, hash) if respond_to?(normalize_method, true)

    unless @md5_builders[model_name].nil?
      hash[:md5_hash] = @md5_builders[model_name].generate(hash)
    end

    hash[:touched_run_id] = @run_id if RUNID_MODELS.include?(model_name)

    add_to_buffer = @md5_builders[model_name].nil?
    add_to_buffer ||= @buffer[model_name].none? { |h| h[:md5_hash] == hash[:md5_hash] }
    @buffer[model_name] << hash if add_to_buffer

    flush(model_class) if @buffer[model_name].count >= @max_buf_size

    hash
  end

  def touch(model_class)
    model_class = model_class.constantize if model_class.is_a?(String)
    model_name  = model_class.name
    return unless RUNID_MODELS.include?(model_name)

    model_class.update_all(touched_run_id: @run_id)
    Hamster.close_connection(model_class)
  end

  private

  def normalize_milb_batters_stat(hash)
    replace_roster_hash(hash)
  end

  def normalize_milb_career_stat(hash)
    replace_roster_hash(hash)
  end

  def normalize_milb_pitchers_stat(hash)
    replace_roster_hash(hash)
  end

  def replace_roster_hash(hash)
    team_id   = hash.delete(:mlb_team_id)
    person_id = hash.delete(:mlb_person_id)
    season    = hash.delete(:season)

    roster = { mlb_team_id: team_id, mlb_person_id: person_id, season: season }
    roster = save_data('MilbRoster', roster)

    hash[:roster_hash] = roster[:md5_hash]
    hash
  end
end
