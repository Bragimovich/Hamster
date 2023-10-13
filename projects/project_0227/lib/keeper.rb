require_relative '../models/oh_professional_licences_runs'
require_relative '../models/oh_professional_licences'

class Keeper

  def initialize
    @run_object = RunId.new(OhProfessionalRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def save_record(data_array)
    OhProfessional.insert_all(data_array)
  end

  def download_status(type)
    status = OhProfessionalRuns.pluck(:download_business).last if type == 'business'
    status = OhProfessionalRuns.pluck(:download_individual).last if type == 'individual'
    status
  end

  def finish_download(type)
    current_run = OhProfessionalRuns.find_by(id: run_id)
    current_run.update download_business: 'finish' if type == 'business'
    current_run.update download_individual: 'finish' if type == 'individual'
  end

  def mark_deleted
    all_old_ids = OhProfessional.where.not(:touch_run_id => run_id).pluck(:id)
    unless all_old_ids.empty?
      all_old_ids.each_slice(5000) { |data| mark_records_deleted(data) }
    end
  end

  def update_rouch_id(touch_run_ids_array)
    OhProfessional.where(:md5_hash => touch_run_ids_array).update_all(:touch_run_id => run_id)
  end

  def mark_records_deleted(ids)
    OhProfessional.where(:id => ids).update_all(:deleted => 1)
  end

  def finish
    @run_object.finish
  end
end
