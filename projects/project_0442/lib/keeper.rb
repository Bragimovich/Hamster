# frozen_string_literal: true

require_relative '../models/il_lc_case_info'
require_relative '../models/il_lc_case_party'
require_relative '../models/il_lc_case_activities'
require_relative '../models/il_lc_case_judgment'
require_relative '../models/il_lc_case_index'
require_relative '../models/il_lc_case_runs'

class  Keeper < Hamster::Harvester
  attr_writer :data_hash

  def initialize(args)
    super
    @run_object = RunId.new(IlLcCaseRuns)
    if args[:download] || args[:auto] || args[:update] || args[:store_and_update]
      last = @run_object.last_id 
      @run_id = IlLcCaseRuns.create(id: last + 1).id 
    else
      @run_id = @run_object.last_id
    end
  end

  def store_index(data)
    IlLcCaseIndex.insert_all(data)
  end

  def store_info
    digest_update(IlLcCaseInfo, @data_hash)                                                                                                        
  end

  def party
    @party_arr = []
    @data_hash[:party_arr].size.times do |i|
      if @data_hash[:party_arr][i]["Responsible Attorney"].size > 0
        h = {
          case_id: @data_hash[:case_id],
          party_name: @data_hash[:party_arr][i]["Responsible Attorney"],
          party_type: @data_hash[:party_arr][i]["Role"],
          data_source_url:  @data_hash[:data_source_url],
          is_lawyer: 1 }

        store_array(IlLcCaseParty, h, @party_arr)
      end

      h = {
        case_id: @data_hash[:case_id],
        party_name: @data_hash[:party_arr][i]["Party"],
        party_type: @data_hash[:party_arr][i]["Role"],
        data_source_url: @data_hash[:data_source_url],
        is_lawyer: 0 }

      store_array(IlLcCaseParty, h, @party_arr)
    end
  end

  def activities
    @activities_arr = []
    @data_hash[:documents_filed_arr].size.times do |i|
      unless @data_hash[:documents_filed_arr][i]["Filed Date"].nil?
        h = {
          case_id: @data_hash[:case_id],
          activity_date: @data_hash[:documents_filed_arr][i]["Filed Date"],
          activity_type: @data_hash[:documents_filed_arr][i]["Document Type"],
          activity_decs: @data_hash[:documents_filed_arr][i]["Document Action"],
          data_source_url: @data_hash[:data_source_url] }

        store_array(IlLcCaseActivities, h, @activities_arr)
      end
    end
    
    @data_hash[:events_previous_arr].size.times do |i|
      unless @data_hash[:events_previous_arr][i]["Event Date"].nil?
        h = {
          case_id: @data_hash[:case_id],
          activity_date: @data_hash[:events_previous_arr][i]["Event Date"],
          activity_type: @data_hash[:events_previous_arr][i]["Event Type"],
          activity_decs: @data_hash[:events_previous_arr][i]["Courtroom"],
          data_source_url: @data_hash[:data_source_url] }

        store_array(IlLcCaseActivities, h, @activities_arr)
      end
    end
  end

  def judgment
    unless @data_hash[:judgment_arr].nil?
      @judgment_arr = []
      @data_hash[:judgment_arr].size.times do |i|
        h = {
          case_id: @data_hash[:case_id],
          party_name: @data_hash[:judgment_arr][i]["Judgment Debtor"],
          #plus_costs: @data_hash[:judgment_arr][i]["Plus Costs?"],
          judgment_amount: @data_hash[:judgment_arr][i]["Judgment Amount"],
          judgment_date: @data_hash[:judgment_arr][i]["Judgment Date"],
          data_source_url:  @data_hash[:data_source_url] }

        store_array(IlLcCaseJudgment, h, @judgment_arr)
      end
    end
  end

  def store_all
    IlLcCaseParty.insert_all(@party_arr) unless @party_arr.nil? || @party_arr.empty?
    IlLcCaseActivities.insert_all(@activities_arr) unless @activities_arr.nil? || @activities_arr.empty?
    IlLcCaseJudgment.insert_all(@judgment_arr) unless @judgment_arr.nil? || @judgment_arr.empty?
  end

  def digest_update(object, h)
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash), deleted: false)
    if digest.nil?
      hash.merge!({ md5_hash: create_md5_hash(hash), run_id: @run_id, touched_run_id: @run_id})
      object.store(hash)
    else
      digest.update(touched_run_id: @run_id)
    end
  end

  def store_array(object, hash, object_arr)
    digest = object.find_by(md5_hash: create_md5_hash(hash), deleted: false)
    if digest.nil?
      hash.merge!({ md5_hash: create_md5_hash(hash), run_id: @run_id, touched_run_id: @run_id})
      object_arr << hash
    else
      digest.update(touched_run_id: @run_id)
    end
  end

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end

  def update_delete_status
    IlLcCaseInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    IlLcCaseParty.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    IlLcCaseActivities.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    IlLcCaseJudgment.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def finish
    @run_object.finish
  end

  def update_delete_status_if_op_update
    IlLcCaseInfo.where(deleted: 0).group(:case_id).having("count(*) > 1").update(deleted: 1)
  end

  def update
    @run_object.status=('update')
  end
end
