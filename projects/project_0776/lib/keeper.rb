require_relative '../models/hs_athlete'
require_relative '../models/hs_athlete_run'
class Keeper
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

  def store(info)
    info.each do |row_info|
    db = HsAthlete.find_by(md5_hash: row_info[:md5_hash], deleted: 0)
    if db.nil?
      HsAthlete.store(row_info)
    else
      if db[:md5_hash] == row_info[:md5_hash]
        db.update(touched_run_id: run_id)
      else
        db.update(deleted: 1)
        NewHampshireInmates.store(row_info)
      end
    end
    end
  end
  private
  def run
    RunId.new(HsAthleteRun)
  end
end
