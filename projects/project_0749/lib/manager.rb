# frozen_string_literal: true

require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize()
    super
    @keeper = Keeper.new
    @parser = Parser.new
  end

  def store
    url = 'https://www.nvsos.gov/SOSServices/DataDownload/CreateEditReport1.aspx'
    store_data('./csv/CampaignFinance.Expn.62375.040623022125.csv', NvRawExpense, url)
    store_data('./csv/CampaignFinance.Cntrbt.62375.040623022125.csv', NvRawContribution, url)
    store_data('./csv/CampaignFinance.Cntrbtrs-.62375.040623022125.csv', NvRawContributor, url)
    store_data('./csv/CampaignFinance.Rpr.62375.040623022125.csv', NvRawReport, url)
    store_data('./csv/CampaignFinance.Cnddt.62375.040623022125.csv', NvRawCandidate, url)
    store_data('./csv/CampaignFinance.Grp.62375.040623022125.csv', NvRawGroup, url)
    @keeper.finish
  end

  private

  def store_data(file, model, data_source_url)
    data_array, md5_array = @parser.parse_data(file, @keeper.run_id, data_source_url)
    @keeper.insert_records(data_array, model)
    @keeper.update_touch_run_id(md5_array, model)
    @keeper.mark_delete(model)
  end
end
