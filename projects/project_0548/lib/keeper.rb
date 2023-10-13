require_relative '../models/mo_saac_ca_info'
require_relative '../models/mo_saac_ca_info_runs'
require_relative '../models/mo_saac_ca_ad_info'
require_relative '../models/mo_saac_case_party'
require_relative '../models/mo_saac_case_activity'
require_relative '../models/mo_saac_case_pdf_aws'
require_relative '../models/mo_saac_case_relations_activity_pdf'

class Keeper
  def initialize
    @run_object = RunId.new(MoSaacCaInfoRuns)
    @run_id = @run_object.run_id
  end

  def ad_ids(hash)
    if !hash.nil?
      hash['run_id'] = @run_id
      hash['touched_run_id'] = @run_id
    end  
    hash
  end  

  def store_ca_info(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    MoSaacCaInfo.insert_all(list_of_hashes)
  end

  def store_ca_ad_info(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    MoSaacCaAdInfo.insert_all(list_of_hashes)
  end
    
  def store_party_info(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    MoSaacCaseParty.insert_all(list_of_hashes)
  end

  def store_case_activity(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    MoSaacCaseActivity.insert_all(list_of_hashes)
  end

  def get_ca_activity_md5(case_id,case_date)
    md5_hashes = MoSaacCaseActivity.where(activity_date: case_date, case_id: case_id).where('activity_type LIKE ?', '%opinion%').pluck(:md5_hash)
  end

  def store_opinion_files(hash)
    hash = ad_ids(hash)
    MoSaacCasePdfAws.insert(hash)
  end
   
  def store_relation_hashes(hash)
    hash = ad_ids(hash)
    MoSaacCaseRelationsActivityPdf.insert(hash)
  end

  def update_touch_run_id(case_info_md5,case_adinfo_md5,party_info,activity_md5)
    update_touch_id(MoSaacCaInfo, case_info_md5.flatten)
    update_touch_id(MoSaacCaAdInfo, case_adinfo_md5.flatten)
    update_touch_id(MoSaacCaseParty, party_info.flatten)
    update_touch_id(MoSaacCaseActivity, activity_md5.flatten)
  end

  def update_opriniontouch_run_id(pdf_md5,rel_md5)
    update_touch_id(MoSaacCasePdfAws, pdf_md5.flatten)
    update_touch_id(MoSaacCaseRelationsActivityPdf, rel_md5.flatten)
  end
  
  def update_touch_id(model, array)
    array.each_slice(5000) { |data| model.where(:md5_hash => data).update_all(:touched_run_id => @run_id) }
  end
  
  def finish
    @run_object.finish
  end
end
