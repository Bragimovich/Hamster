require_relative '../models/maxpreps_school'
require_relative '../models/maxpreps_schools_director'
require_relative '../models/maxpreps_schools_run'
require_relative '../models/city'

class Keeper
  def initialize
    @run_id = run.run_id
    @count  = 0
  end

  attr_reader :run_id, :count

  def status=(new_status)
    run.status = new_status
  end

  def finish
    run.finish
  end

  def get_cities(state)
    City.where(bad_matching: nil, state_name: state).pluck(:short_name)
  end

  def save_school_director(school)
    director = school.delete(:director)
    url      = school[:data_source_url]
    school[:director_id] = save_director(director, url)
    md5 = MD5Hash.new(columns: school.keys)
    school[:md5_hash]       = md5.generate(school)
    school[:run_id]         = run_id
    school[:touched_run_id] = run_id
    school_old = MaxprepsSchool.find_by(md5_hash: school[:md5_hash], deleted: 0)

    if school_old.nil?
      MaxprepsSchool.store(school)
    elsif school_old[:md5_hash] == school[:md5_hash]
      school_old.update(touched_run_id: run_id)
    elsif school_old[:md5_hash] != school[:md5_hash]
      school_old.update({deleted: 1})
      MaxprepsSchool.store(school)
    end
    @count += 1

    # school_old = MaxprepsSchool.find_by(data_source_url: school[:data_source_url], deleted: 0)
    # if school_old
    #   school_old.update(school)
    #   @count += 1
    # end
  end

  private

  def save_director(director, url)
    return unless director

    director_info = { name: director, data_source_url: url }
    md5           = MD5Hash.new(columns: director_info.keys)
    md5.generate(director_info)
    md5_hash                       = md5.hash
    director_info[:md5_hash]       = md5_hash
    director_info[:run_id]         = run_id
    director_info[:touched_run_id] = run_id
    director_bd  = MaxprepsSchoolsDirector.find_by(md5_hash: md5_hash, deleted: 0)

    if director_bd.nil?
      MaxprepsSchoolsDirector.store(director_info).id
    elsif director_bd.md5_hash == md5_hash
      director_bd.update(touched_run_id: run_id, deleted: 0)
      director_bd.id
    else
      director_bd.update(deleted: 1)
      MaxprepsSchoolsDirector.store(director_info).id
    end
  end

  def run
    RunId.new(MaxprepsSchoolsRun)
  end
end
