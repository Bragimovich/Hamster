require_relative '../models/arizona_professional_licenseing_runs'
require_relative '../models/arizona_professional_licenseing'
require_relative '../models/arizona_professional_licenseing_business'
require_relative '../models/arizona_cities_and_zips'

class Keeper

  DB_MODELS = {"individual" => ArizonaProfessionalLicenseing, "business" => ArizonaProfessionalLicenseingBusiness}
  RUNS_COLUMNS = {"individual" => :download_individual_status, "business" => :download_business_status}

  def initialize
    @run_object = RunId.new(ArizonaProfessionalLicenseingRuns)
    @run_id = @run_object.run_id
  end

  def finish_download_status(type)
    ArizonaProfessionalLicenseingRuns.where(id: run_id).update(RUNS_COLUMNS[type] => "finish")
  end

  def get_download_status
    individual_status = ArizonaProfessionalLicenseingRuns.where(id: run_id).pluck(:download_individual_status)
    business_status   = ArizonaProfessionalLicenseingRuns.where(id: run_id).pluck(:download_business_status)
    individual_status.concat(business_status)
  end

  attr_reader :run_id

  def insert_records(hash_array,key)
    DB_MODELS[key].insert_all(hash_array)
  end

  def fetch_db_inserted_md5_hash(key)
    DB_MODELS[key].pluck(:md5_hash)
  end

  def fetch_db_cities(state)
    ArizonaCitiesAndZips.where(state: state).pluck(:primary_city).uniq
  end

  def fetch_db_zipcodes(city)
    ArizonaCitiesAndZips.where(primary_city: city).pluck(:zip_char)
  end

  def get_max(value)
    value.max
  end

  def mark_deleted(type)
    model = type == 'individual' ? ArizonaProfessionalLicenseing : ArizonaProfessionalLicenseingBusiness
    ids_extract = model.where(deleted: 0).group(:link).having("count(*) > 1").pluck("link, GROUP_CONCAT(id)")
    all_old_ids = []
    ids_extract.each do |value|
      ids = value[-1].split(",").map(&:to_i)
      ids.delete get_max(ids)
      all_old_ids << ids
    end
    all_old_ids = all_old_ids.flatten
    all_old_ids.each_slice (10000) do |old_ids|
      model.where(id: old_ids).update_all(deleted: 1)
    end
  end

  def finish
    @run_object.finish
  end
end
