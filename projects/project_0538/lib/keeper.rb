require_relative '../models/al_accountability_indicators'
require_relative '../models/al_administrators'
require_relative '../models/al_college_career_readiness'
require_relative '../models/al_enrollment'
require_relative '../models/al_general_info'
require_relative '../models/al_schools_assessment_by_levels'
require_relative '../models/al_schools_assessment'
require_relative '../models/al_runs'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = safe_operation(AlRuns) { |model| RunId.new(model) }
    @run_id = safe_operation(AlRuns) { @run_object.run_id }
    @schools_matched = nil
  end

  def store_data(data, model, relation: false)
    data = [data] unless data.is_a?(Array) 
    data = add_relations(data, relation) if relation
    entry = nil

    safe_operation(model) do |model_s|
      data.each do |hash|
        hash = add_md5_hash(hash)
        find_dig = model_s.find_by(md5_hash: hash[:md5_hash])
        if find_dig.nil?
          entry = model_s.store(hash.merge(run_id: @run_id, touched_run_id: @run_id))
        else
          entry = model_s.update(find_dig.id, touched_run_id: @run_id)
        end
      end
    end
    entry
  end

  def store_public_or_private_data(general_hash, admins_data)
    system_name = general_hash.delete(:system_name)
    if system_name == 'Other Agencies' && general_hash[:name] == 'Alabama State Department of Education'
      general_hash[:school_type] = nil
      general_hash[:is_district] = nil
      store_data(general_hash, AlGeneralInfo)
    else
      district_id = find_or_insert_district(system_name)
      general_hash = general_hash.merge(district_id: district_id)
      general_id = store_data(general_hash, AlGeneralInfo).id
      admins_data.map { |hash| hash.merge(general_id: general_id) }.each { |admins_hash| store_data(admins_hash, AlAdministrators) }
    end
  end

  def add_relations(data, relation)
    set_data_from_db
    data.map! do |hash|
      school = hash.delete(:school_name)
      system_name = hash.delete(:system_name)
      school_id = schools_matched.find { |arr| arr[0] == school && arr[1] == system_name }.last rescue nil
      if school_id.present?
        hash.merge!(general_id: school_id)
      elsif school != system_name
        district_id = find_or_insert_district(system_name)
        school_id = find_or_insert_school(school, district_id)
        hash.merge!(general_id: school_id)
      elsif school == system_name
        district_id = find_or_insert_district(system_name)
        hash.merge!(general_id: district_id)
      end
    end
    data
  end

  def find_or_insert_district(name)
    district_id = districts_in_db[name] rescue nil
    district_id ||= check_district_by_name(name)
    return district_id if district_id.present?
    hash = {is_district: 1, name: name, data_source_url: Parser::URL_GENERAL_INFO}
    store_data(hash, AlGeneralInfo).id
  end

  def find_or_insert_school(name, district_id)
    school_id = safe_operation(AlGeneralInfo) { |model| model.find_by(is_district: 0, name: name,  district_id: district_id, deleted: 0)&.id }
    return school_id if school_id
    hash = {is_district: 0, name: name, district_id: district_id, data_source_url: Parser::URL_GENERAL_INFO}
    store_data(hash, AlGeneralInfo).id
  end

  def store_assessment_data(main_hash, level_hashes)
    assessment_id = store_data(main_hash, AlSchoolsAssessment, relation: :general_id).id
    level_hashes.map! { |hash| hash.merge(assessment_id: assessment_id) }
    store_data(level_hashes, AlSchoolsAssessmentByLevels)
  end

  def update_numbers_columns(hash)
    school = hash[:school_name]
    distict = hash[:system_name]
    district_id = check_district_by_name(distict)
    if district_id
      safe_operation(AlGeneralInfo) { |model| model.find_by(id: district_id).update(number: hash[:system_code]) }
      school_id = check_school(school, district_id)
      safe_operation(AlGeneralInfo) { |model| model.find_by(id: school_id).update(number: hash[:school_code]) } if school_id
    end
  end

  def add_md5_hash(data_hash, result: 'full')
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md_5 = Digest::MD5.hexdigest(data_string)
    return md_5 if result == 'only_md_5'
    data_hash.merge(md5_hash: md_5)
  end

  def update_delete_status(*models)
    models.each { |model| safe_operation(model) { |model_s| model_s.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1) } }
  end

  def finish
    safe_operation(AlRuns) { @run_object.finish }
  end

  def mark_as_started_download
    safe_operation(AlRuns) { @run_object.status = 'download started' }
  end

  def mark_as_finished_download
    safe_operation(AlRuns) { @run_object.status = 'download finished' }
  end

  def mark_as_started_store
    safe_operation(AlRuns) { |model| @run_object.status = 'store started' }
  end

  private

  attr_reader :schools_matched, :districts_in_db

  def set_data_from_db
    @schools_matched ||= get_schools_matched
    @districts_in_db ||= get_districts_in_db.pluck(:name, :id).to_h rescue nil
  end

  def get_schools_matched
    all_districts, all_schools = safe_operation(AlGeneralInfo) { |model| model.where(deleted: 0).where.not(is_district: nil).partition { |el| el.is_district } }
    return if all_schools.empty? || all_districts.empty?
    result = all_schools.each_with_object([]) do |school_row, arr|
      district = all_districts.find { |distr| distr.id == school_row.district_id }.name
      arr << [school_row.name, district, school_row.id ]
    end
    result
  end

  def get_districts_in_db
    safe_operation(AlGeneralInfo) { |model| model.where(is_district: 1, deleted: 0) }
  end

  def check_district_by_name(name)
    if name == 'Alabama State Department of Education'
      safe_operation(AlGeneralInfo) { |model| model.find_by(is_district: nil, name: name, deleted: 0)&.id }
    else
      safe_operation(AlGeneralInfo) { |model| model.find_by(is_district: 1, name: name, deleted: 0)&.id }
    end
  end

  def check_school(name, district_id)
    safe_operation(AlGeneralInfo) { |model| model.find_by(is_district: 0, name: name, district_id: district_id, deleted: 0)&.id }
  end

  def safe_operation(model) 
    begin
      yield(model) if block_given?
    rescue  ActiveRecord::ConnectionNotEstablished, Mysql2::Error::ConnectionError, 
            ActiveRecord::StatementInvalid, ActiveRecord::LockWaitTimeout => e
      begin
        puts "#{e.message}"
        puts '*'*77, "Reconnect!", '*'*77
        sleep 5
        model.connection.reconnect!
        # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Reconnecting..."
      rescue => e
        puts "#{e.class}: #{e.message}\n"
        retry
      end
    retry
    end
  end
end
