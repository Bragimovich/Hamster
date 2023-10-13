class MaxprepsComKeeper
  require_relative '../models/maxpreps_com_runs'
  require_relative '../models/maxpreps_com_schools'
  require_relative '../models/maxpreps_com_rosters'
  require_relative '../models/maxpreps_com_games'
  require_relative '../models/city'
  require_relative '../models/state'

  def initialize
    super
    @run_id = run.run_id
  end

  attr_reader :run_id

  def status=(new_status)
    run.status = new_status
  end

  def finish
    run.finish
  end

  def get_cities(name)
    City.where(bad_matching: nil, state_name: name).map(&:short_name)
  end

  def save_school(school)
    athletic_level_id = '7812442d-1329-427a-9369-b8697e846c2f' #High School
    athletic_sport_id = { baseball: '443da90c-f72d-418d-a1b9-ebb86184105f' } #Baseball
    sport   = school.delete(:sport).to_sym
    school  = school.merge({ athletic_sport_id: athletic_sport_id[sport] })
    school  = school.merge({ athletic_level_id: athletic_level_id })
    school[:name] = school[:school_name]
    school[:name] += " #{school[:team_nickname]}" unless school[:team_nickname].nil?
    columns = school.keys
    md5     = MD5Hash.new(columns: columns)
    md5.generate(school)
    @school_md5       = md5.hash
    school[:md5_hash] = md5.hash
    school[:run_id]   = run_id
    MaxprepsComSchools.store(school)
  end

  def save_player(player)
    columns = player.keys
    md5     = MD5Hash.new(columns: columns)
    md5.generate(player)
    school_id = MaxprepsComSchools.find_by(md5_hash: @school_md5).id
    player.merge!(md5_hash: md5.hash, run_id: run_id, school_id: school_id)
    MaxprepsComRosters.store(player)
  end

  private

  def run
    RunId.new(MaxprepsComRuns)
  end

end
