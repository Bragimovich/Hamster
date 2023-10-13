require_relative '../models/ut_saac_case_runs'
require_relative '../models/ut_saac_case_info'
require_relative '../models/ut_saac_case_additional_info'
require_relative '../models/ut_saac_case_party'
require_relative '../models/ut_saac_case_activities'
require_relative '../models/ut_saac_case_pdfs_on_aws'
require_relative '../models/ut_saac_case_relations_info_pdf'
require_relative '../models/ut_saac_case_unfetched_pdfs'

class Keeper
  def initialize
    @run_object = RunId.new(CaseRuns)
    @run_id = @run_object.run_id
  end

  def insert_case_info(name, data_array)
    model = name.constantize
    model.insert_all(data_array) unless ((data_array.empty? )|| (data_array.nil?))
  end

  def unparsed_pdf_links
    CaseUnfetchedPdfs.pluck(:data_source_url)
  end

  def court_ids(court_id)
    CaseInfo.where(:court_id => court_id).pluck(:case_id, :data_source_url)
  end

  def already_inserted_links
    CaseInfo.pluck(:data_source_url)
  end

  attr_reader :run_id

  def finish
    @run_object.finish
  end
end
