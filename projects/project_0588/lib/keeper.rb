require_relative '../models/raw_nj_sc_case_activities'
require_relative '../models/raw_nj_sc_case_additional_info'
require_relative '../models/raw_nj_sc_case_info'
require_relative '../models/raw_nj_sc_case_party'
require_relative '../models/raw_nj_sc_case_pdfs_on_aws'
require_relative '../models/raw_nj_sc_case_relations_activity_pdf'
require_relative '../models/nj_sc_case_runs'

class Keeper
  def initialize
    @run_object = RunId.new(NjScCaseRuns)
    @run_id = @run_object.run_id
  end
  
  def store_data(data_hash)
    return if RawNjScCaseInfo.where(case_id: data_hash[:nj_sc_case_info][:case_id]).present?
    RawNjScCaseInfo.insert(data_hash[:nj_sc_case_info])
    data_hash[:nj_sc_case_activities].each do |case_activity|
      RawNjScCaseActivities.insert(case_activity)
    end
    RawNjScCaseAdditionalInfo.insert(data_hash[:nj_sc_case_additional_info])
    data_hash[:nj_sc_case_party].each do |case_party|
      RawNjScCaseParty.insert(case_party)
    end
    RawNjScCasePdfsOnAws.insert(data_hash[:nj_sc_case_pdfs_on_aws])
    RawNjScCaseRelationsActivityPdf.insert(data_hash[:nj_sc_case_relations_activity_pdf])
  end

  def finish
    @run_object.finish
  end
end
