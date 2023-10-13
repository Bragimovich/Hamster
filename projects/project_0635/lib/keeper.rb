require_relative '../models/new_tennessee_campaign_finance_runs'
require_relative '../models/new_tennessee_campaign_finance_committees'
require_relative '../models/new_tennessee_campaign_finance_reports'
require_relative '../models/new_tennessee_campaign_finance_contributions'
require_relative '../models/new_tennessee_campaign_finance_expenditures'

class Keeper
  
  DB_MODELS = {"committees" => NewTennesseeCampaignFinanceCommittees, "reports" => NewTennesseeCampaignFinanceReports, "contributions" => Contributions, "expenditures" => Expenditures}
  def initialize
    @run_object = RunId.new(NewTennesseeCampaignFinanceRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def get_download_status(col)
    NewTennesseeCampaignFinanceRuns.where("id = #{run_id}").pluck("#{col}_status").last
  end

  def finish_download(col)
    current_run = NewTennesseeCampaignFinanceRuns.find_by(id: run_id)
    current_run.update("#{col}_status" => 'finish')
  end

  def make_insertions(model, hash_array)
    DB_MODELS[model].insert_all(hash_array) unless hash_array.empty?
  end

  def fetch_committees_reports(model, value)
    DB_MODELS[model].all.pluck(:id, :"#{value}")
  end

  def fetch_reports(model)
    DB_MODELS[model].all.pluck(:id, :committee_id, :report_link, :submited_on, :depreciated)
  end

  def finish
    @run_object.finish
  end
end
