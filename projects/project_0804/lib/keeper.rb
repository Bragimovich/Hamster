require_relative '../models/university_of_vermont'
require_relative '../models/university_of_vermont_clean'
require_relative '../models/university_of_vermont_origin'

class Keeper
  def store(data)
    data.each {|info| info.delete(:idx)}
    data.each {|info| UniversityVermontOrigin.store(info)}
  end

  def update
    data = UniversityVermont.all
    data.each do |entry|
      base_pay_db = entry.base_pay.gsub(',', '.')
      base_pay_db.delete!('$')
      clean_pay   = base_pay_db.split('.')
      if clean_pay.size == 2
        entry.base_pay = clean_pay.join('').squish
      elsif
        clean_pay.size == 3
        entry.base_pay = (clean_pay[0] + clean_pay[1] + '.' + clean_pay[2]).squish
      end
    end
    data.each do |info|
      UniversityVermontClean.store(id: info.id,
                                   name: info.name,
                                   primary_job_title: info.primary_job_title,
                                   base_pay: info.base_pay,
                                   salary_data: info.salary_data,
                                   data_source_url: info.data_source_url,
                                   run_id: info.run_id,
                                   created_by: info.created_by,
                                   created_at: info.created_at,
                                   touched_run_id: info.touched_run_id,
                                   deleted: info.deleted
      )
    end
  end

  def rebase_table
    data = UniversityVermontClean.all
    data.each do |info|
    UniversityVermontOrigin.store(id: info.id,
                                  name: info.name,
                                  primary_job_title: info.primary_job_title,
                                  salary_data: info.salary_data,
                                  data_source_url: info.data_source_url,
                                  run_id: info.run_id,
                                  created_by: info.created_by,
                                  created_at: info.created_at,
                                  touched_run_id: info.touched_run_id,
                                  deleted: info.deleted
    )
    end
  end
end
