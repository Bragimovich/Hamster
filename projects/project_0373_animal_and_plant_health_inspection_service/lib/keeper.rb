require_relative '../models/table'
require_relative '../models/table_cateogry'
require_relative '../models/table_cateogry_article_links'
require_relative '../models/us_dept_doa_aphis_programs_cateogry_article_links'
require_relative '../models/us_dept_doa_aphis_programs_cateogry'
require_relative '../models/us_dept_doa_aphis_programs'

class Keeper

  DB_MODELS_TABLES = {"animal_and_plant_health" => Table, "animal_and_plant_health_programs" => UsDeptDoaAphisPrograms}
  DB_MODELS_LINKS = {"animal_and_plant_health" => TableTAlinks, "animal_and_plant_health_programs" => UsDeptDoaAphisProgramsAlinks}
  DB_MODELS_CATEGORY = {"animal_and_plant_health" => TableCateogries, "animal_and_plant_health_programs" => UsDeptDoaAphisProgramsCateogries}


  attr_reader :run_id

  def pluck_links(key)
    DB_MODELS_TABLES[key].pluck(:link)
  end

  def pluck_catagory(key)
    DB_MODELS_CATEGORY[key].pluck(:cateogry)
  end

  def pluck_id(key, cateogry)
    DB_MODELS_CATEGORY[key].where(:cateogry => cateogry).pluck(:id)
  end

  def insert_records(key, hash_array)
    DB_MODELS_TABLES[key].insert_all(hash_array)
  end

  def insert_records_links(key, id, link)
    DB_MODELS_LINKS[key].insert(cateogry_id: id[0], article_link: link)
  end

  def insert_records_category(key, cateogry)
    DB_MODELS_CATEGORY[key].insert(cateogry: cateogry)
  end

end
