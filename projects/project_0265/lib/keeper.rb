require_relative '../models/tx_general_assembly_house_committees'
require_relative '../models/tx_general_assembly_senate_committees'
require_relative '../models/tx_general_assembly_senate_committee_members'
require_relative '../models/tx_general_assembly_house_committee_members'
require_relative '../models/tx_general_assembly_bills'
require_relative '../models/tx_general_assembly_bill_actions'
require_relative '../models/tx_general_assembly_runs'

class Keeper

  DB_MODELS = {
    "s_committees" => AssemblySenateCommetie,
    "h_committees" => AssemblyHouseCommetie,
    "s_committee_members" => AssemblySenateCommetieMembers,
    "h_committee_members" => AssemblyHouseCommetieMembers,
    "bills" => GeneralAssemblyBills,
    "bills_actions" => GeneralAssemblyBillActions,
  }

  def initialize
    @run_object = RunId.new(GeneralAssemblyRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_record(data_hash, key)
    DB_MODELS[key].insert(data_hash)
    DB_MODELS[key].where(md5_hash: data_hash["md5_hash"]).pluck(:id)[0]
  end

  def inserted_links(key)
    DB_MODELS[key].where(touched_run_id: run_id).pluck(:data_source_url)
  end

  def finish_download
    current_run = GeneralAssemblyRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def download_status
    GeneralAssemblyRuns.pluck(:download_status).last
  end

  def update_touch_run_id(md5_array, key)
    md5_array.each_slice(5000) do |md5|
      DB_MODELS[key].where(md5_hash: md5).update_all(touched_run_id: run_id) unless md5.empty?
    end
  end

  def delete_using_touch_id(key, committee_id)
    committee_id.each do |id|
      DB_MODELS[key].where(committee_id: id).where.not(touched_run_id: run_id).update_all(deleted: 1)
    end
  end

  def delete_bills(key, legis_session)
    DB_MODELS[key].where.not(touched_run_id: run_id).where(legislative_session: legis_session).update_all(deleted: 1)
  end

  def insert_array(array, key)
    DB_MODELS[key].insert_all(array)
  end

  def get_id(key, link)
    DB_MODELS[key].where(data_source_url: link).pluck(:id).first
  end

  def finish
    @run_object.finish
  end

end
