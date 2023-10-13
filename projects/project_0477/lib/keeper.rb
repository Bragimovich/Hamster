require_relative '../models/wa_saac_case_party'
require_relative '../models/wa_saac_additional_info'
require_relative '../models/wa_saac_case_info'
require_relative '../models/wa_saac_case_pdfs_on_aws'
require_relative '../models/wa_saac_case_activities'
require_relative '../models/wa_saac_case_info_runs'
require_relative '../models/wa_saac_case_relations_info_pdf'

class Keeper
  def initialize
    @run_object = RunId.new(WaSaacCaseInfoRuns)
    @all_pdf_links_in_db = WaSaacCasePdfsOnAws.pluck(:source_link)
    @run_id = @run_object.run_id
  end

  def store_activites(list_of_hashes)
    list_of_hashes.each do |hash|
      hash = add_md5_hash(hash)
      hash = remove_comma_from_case_id(hash)
      check = WaSaacCaseActivities.where(md5_hash: hash['md5_hash']).as_json.first
      if check
        WaSaacCaseActivities.udpate_touched_run_id(check['id'],@run_id)
      else
        WaSaacCaseActivities.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    end
  end
  
  def store_parties(list_of_hashes)
    list_of_hashes.each do |hash|
      hash = add_md5_hash(hash)
      hash = remove_comma_from_case_id(hash)
      check = WaSaacCaseParty.where(md5_hash: hash['md5_hash']).as_json.first
      if check
        WaSaacCaseParty.udpate_touched_run_id(check['id'],@run_id)
      else
        WaSaacCaseParty.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      end
    end
  end

  def store_additional_info(hash)
    hash = add_md5_hash(hash)
    hash = remove_comma_from_case_id(hash)
    hash = HashWithIndifferentAccess.new(hash)
    check = WaSaacAdditionalInfo.where(md5_hash: hash['md5_hash']).as_json.first
    if check && check['md5_hash'] == hash[:md5_hash]
      WaSaacAdditionalInfo.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      WaSaacAdditionalInfo.mark_deleted(check['id'])
      WaSaacAdditionalInfo.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      WaSaacAdditionalInfo.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def store_case_info(hash)
    hash = add_md5_hash(hash)
    hash = remove_comma_from_case_id(hash)
    check = WaSaacCaseInfo.where(data_source_url: hash['data_source_url']).as_json.first
    if check && check['md5_hash'] == hash['md5_hash']
      WaSaacCaseInfo.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      WaSaacCaseInfo.mark_deleted(check['id'])
      WaSaacCaseInfo.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      WaSaacCaseInfo.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end
  
  def store_aws_link(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    hash = remove_comma_from_case_id(hash)
    WaSaacCasePdfsOnAws.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
  end

  def pdf_link_exits_in_db?(pdf_link)
    @all_pdf_links_in_db.include?(pdf_link)
  end

  def update_touched_run_id_of_pdf_on_aws(pdf_link)
    check = WaSaacCasePdfsOnAws.where(source_link: pdf_link).first
    WaSaacCasePdfsOnAws.udpate_touched_run_id(check['id'],@run_id)
  end

  def update_touched_run_id_of_case_info_relation_to_pdf(pdf_link)
    check = WaSaacCasePdfsOnAws.where(source_link: pdf_link).as_json.first
    if check
      temp = WaSaacCaseRelationsInfoPdf.where(case_pdf_on_aws_md5: check['md5_hash']).as_json.first
      if temp
        WaSaacCaseRelationsInfoPdf.udpate_touched_run_id(temp['id'],@run_id)
      end
    end
  end

  def store_case_relations_info_pdf(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    hash = remove_comma_from_case_id(hash)
    WaSaacCaseRelationsInfoPdf.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
  end

  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end

  def remove_comma_from_case_id(hash)
    if hash.include?('case_id')
      hash['case_id'] = hash['case_id'].gsub(',','')
    end
    hash
  end

  def finish
    WaSaacCaseInfo.mark_inactive_cases
    @run_object.finish
  end
end
