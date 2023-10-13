require_relative 'wisc_case_relations_activity_pdf'
require_relative 'wisc_case_relations_info_pdf'
require_relative './active_record_base'

class WiscCasePdfsOnAws < ActiveRecordBase
  self.table_name = 'wisc_case_pdfs_on_aws'

  def self.store(values, rel_hash, model)
    self.transaction do
      self.create!(values)
      self.save_relations(rel_hash, values[:md5_hash], model)
    end
  rescue ActiveRecord::RecordNotUnique
    # To prevent not unique error
  end

  private

  def self.save_relations(rel_hash, aws_md5, model)
    if model == :activity
      WiscCaseRelationsActivityPdf.create!(case_activities_md5: rel_hash, case_pdf_on_aws_md5: aws_md5)
    else
      WiscCaseRelationsInfoPdf.create!(case_info_md5: rel_hash, case_pdf_on_aws_md5: aws_md5)
    end
  end
end
