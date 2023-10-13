require_relative '../models/school_runs'
require_relative '../models/school_info'
require_relative '../models/school_directors'
require_relative '../models/school_sports_type'
require_relative '../models/school_departments'
require_relative '../models/school_cooperative_teams'
require_relative '../models/school_sport_type_vs_school_info'

class Keeper
  def initialize
    @run_object = RunId.new(SchoolRuns)
    @run_id = @run_object.run_id
  end

  def store_school_info(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    check = SchoolInfo.where(data_source_url: hash['data_source_url'], deleted: false).as_json.first  
    if check && check['md5_hash'] == hash['md5_hash']
      SchoolInfo.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      SchoolInfo.mark_deleted(check['id'])
      cop_team_ids = SchoolCooperativeTeams.where(opponent_school_id: check['id']).or(SchoolCooperativeTeams.where(host_school_id: check['id'])).pluck(:id)
      cop_team_ids.each do |id|
        SchoolCooperativeTeams.mark_deleted(id)
      end
      SchoolInfo.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      SchoolInfo.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def store_school_cooperative_teams(list_of_hashes)
    list_of_hashes.each do |hash|
      hash = add_md5_hash(hash)
      hash = HashWithIndifferentAccess.new(hash)
      check = SchoolCooperativeTeams.where(md5_hash: hash[:md5_hash]).as_json.first
      if check && check['md5_hash'] == hash['md5_hash']
        SchoolCooperativeTeams.udpate_touched_run_id(check['id'],@run_id)
      else
        SchoolCooperativeTeams.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    end
  end

  def store_school_type_and_school_info(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    check = SchoolSportsTypesVsSchoolInfo.where(md5_hash: hash[:md5_hash]).as_json.first
    if check && check['md5_hash'] == hash['md5_hash']
      SchoolSportsTypesVsSchoolInfo.udpate_touched_run_id(check['id'],@run_id)
    else
      SchoolSportsTypesVsSchoolInfo.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def store_school_directors(list_of_hashes)
    list_of_hashes.each do |hash|
      hash = add_md5_hash(hash)
      hash = HashWithIndifferentAccess.new(hash)
      check = SchoolDirectors.where(md5_hash: hash[:md5_hash]).as_json.first
      if check
        SchoolDirectors.udpate_touched_run_id(check['id'], @run_id)
      else
        SchoolDirectors.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    end
  end

  def get_department_id(dept)
    SchoolDepartments.where(division: dept).first.id
  end

  def get_school_info_id(data_source_url)
    SchoolInfo.where(data_source_url: data_source_url, deleted: false)&.first&.id
  end

  def get_school_info_id_by_school_name(school_name)
    SchoolInfo.where(short_name: school_name, deleted: false)&.first&.id
  end

  def store_school_sports(list_of_hashes)
    list_of_hashes.each do |hash|
      SchoolSportsTypes.insert(hash)
    end
  end

  def get_school_sport_id(sport_name)
    SchoolSportsTypes.where(sport_name: sport_name)&.first&.id
  end

  def store_school_departments(list_of_hashes)
    list_of_hashes.each do |hash|
      SchoolDepartments.insert(hash)
    end
  end

  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end

  def finish
    @run_object.finish
  end
end