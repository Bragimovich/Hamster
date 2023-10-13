# require model files here
require_relative '../models/wi_campaign_finance_run'
require_relative '../models/wi_campaign_finance_contributor'
require_relative '../models/wi_campaign_finance_expenditure'
require_relative '../models/wi_campaign_finance_committee'
class Keeper < Hamster::Keeper
  attr_reader :run_id

  def initialize
    super
    @run_object = RunId.new(WiCampaignFinanceRun)
    @run_id = @run_object.run_id
    @max_buffer_size = 500
    @receipt_buffer    = []
    @expense_buffer    = []
    @registrant_buffer = []

  end

  def store(hash_data)
    # write store logic here
  end

  def store_receipt(hash_data)
    @receipt_buffer << hash_data.merge(touched_run_id: @run_id)
    flush_receipt if @receipt_buffer.size >= @max_buffer_size
  end

  def flush_receipt
    return if @receipt_buffer.count.zero?
    data_array = []
    run_ids = Hash[WiCampaignFinanceContributor.where( md5_hash: @receipt_buffer.map { |h| h[:md5_hash] } ).map { |r| [r.md5_hash, r.run_id] }]
    @receipt_buffer.each do |hash|
      data_array << hash.merge(run_id: run_ids[hash[:md5_hash]] || @run_id, updated_at: Time.now)
    end
    WiCampaignFinanceContributor.upsert_all(data_array)
    logger.info "#{'-*-'*10}> Added ReceiptList: #{WiCampaignFinanceContributor.count}"
    Hamster.close_connection(WiCampaignFinanceContributor)
    @receipt_buffer = []
  end

  def store_expense(hash_data)
    @expense_buffer << hash_data.merge(touched_run_id: @run_id)
    flush_expense if @expense_buffer.size >= @max_buffer_size
  end

  def flush_expense
    return if @expense_buffer.count.zero?
    data_array = []
    run_ids = Hash[WiCampaignFinanceExpenditure.where( md5_hash: @expense_buffer.map { |h| h[:md5_hash] } ).map { |r| [r.md5_hash, r.run_id] }]
    @expense_buffer.each do |hash|
      data_array << hash.merge(run_id: run_ids[hash[:md5_hash]] || @run_id, updated_at: Time.now)
    end
    WiCampaignFinanceExpenditure.upsert_all(data_array)
    logger.info "#{'-*-'*10}> Added ExpenseList: #{WiCampaignFinanceExpenditure.count}"
    Hamster.close_connection(WiCampaignFinanceExpenditure)
    @expense_buffer = []
  end

  def store_registrant(hash_data)
    @registrant_buffer << hash_data.merge(touched_run_id: @run_id)
    flush_registrant if @registrant_buffer.size >= 50
  end

  def flush_registrant
    return if @registrant_buffer.count.zero?
    data_array = []
    run_ids = Hash[WiCampaignFinanceCommittee.where( md5_hash: @registrant_buffer.map { |h| h[:md5_hash] } ).map { |r| [r.md5_hash, r.run_id] }]
    @registrant_buffer.each do |hash|
      data_array << hash.merge(run_id: run_ids[hash[:md5_hash]] || @run_id, updated_at: Time.now)
    end

    WiCampaignFinanceCommittee.upsert_all(data_array)
    logger.info "#{'-*-'*10}> Added RegistrantList: #{WiCampaignFinanceCommittee.count}"
    Hamster.close_connection(WiCampaignFinanceCommittee)
    @registrant_buffer = []
  end

  def finish
    @run_object.finish
  end
end
