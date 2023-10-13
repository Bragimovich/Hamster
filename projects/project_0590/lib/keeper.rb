# frozen_string_literal: true
require_relative '../models/de_sc_case_activities'
require_relative '../models/de_sc_case_additional_info'
require_relative '../models/de_sc_case_info'
require_relative '../models/de_sc_case_party'
require_relative '../models/de_sc_case_pdfs_on_aws'
require_relative '../models/de_sc_case_relations_activity_pdf'
require_relative '../models/de_sc_case_runs'


class Keeper
  def initialize
    @run_object = RunId.new(DeScCaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def get_cases()
    DeScCaseInfo.pluck(:case_id)
  end

  def insert_case_info(data_hash)
    DeScCaseInfo.insert(data_hash)
  end

  def insert_case_additional_info(data_hash)
    DeScCaseAdditionalInfo.insert(data_hash)
  end

  def insert_case_activities(data_hash)
    DeScCaseActivities.insert(data_hash)
  end

  def insert_case_party(data_hash)
    DeScCaseParty.insert_all(data_hash)
  end

  def insert_case_pdfs_on_aws(data_hash)
    DeScCasePdfsAws.insert(data_hash)
  end

  def insert_relations_activity_pdf(data_hash)
    DeScCaseRealtionsActivityPdf.insert(data_hash)
  end

  def finish
    @run_object.finish
  end
end
