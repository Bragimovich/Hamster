require_relative '../models/sba_list_scorecard_runs'
require_relative '../models/sba_list_raw_senate_person'
require_relative '../models/sba_list_scorecard_raw_person'
require_relative '../models/sba_list_raw_house_person'
require_relative '../models/sba_list_raw_score_votes'
require_relative '../models/sba_list_raw_activities'

class Keeper
  def initialize
    @run_object = RunId.new(Sba_List_Scorecard)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def already_fetched_records
    Sba_List_Scorecard_Raw_Person.where(:touched_run_id => run_id).pluck(:data_source_url)
  end

  def download_status
    Sba_List_Scorecard.pluck(:download_status).last
  end

  def already_inserted_md5_hash
    Sba_List_Raw_Senate_Person.pluck(:md5_hash)
  end

  def finish_download
    current_run = Sba_List_Scorecard.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def insert_person(hash, model)
    md5_hash = hash.delete(:md5_hash)
    model.insert(hash)
    model.where(:md5_hash => md5_hash).pluck(:id)[0]
  end

  def insert_senate_hash(raw_senate_hash, raw_hash, raw_vote_data_all, raw_activities_data_all)
    Sba_List_Raw_Senate_Person.insert(raw_senate_hash)
    Sba_List_Scorecard_Raw_Person.insert(raw_hash)
    Sba_List_Raw_Score_Votes.insert_all(raw_vote_data_all)
    Sba_List_Raw_Activities.insert_all(raw_activities_data_all)
  end

  def insert_representative_hash(raw_hash, raw_house_hashes, raw_vote_data_all, raw_activities_data_all)
    Sba_List_Scorecard_Raw_Person.insert(raw_hash)
    Sba_List_Raw_House_Person.insert_all(raw_house_hashes)
    Sba_List_Raw_Score_Votes.insert_all(raw_vote_data_all)
    Sba_List_Raw_Activities.insert_all(raw_activities_data_all)
  end

  def update_touch_run_id(raw_senate_md5_array, raw_hash_md5_array, raw_house_md5_array, raw_vote_md5_array, raw_activities_md5_array)
    update_touch_run_id_with_array(Sba_List_Raw_Senate_Person, raw_senate_md5_array) rescue []
    update_touch_run_id_with_array(Sba_List_Scorecard_Raw_Person, raw_hash_md5_array)
    update_touch_run_id_with_array(Sba_List_Raw_House_Person, raw_house_md5_array) rescue []
    update_touch_run_id_with_array(Sba_List_Raw_Score_Votes, raw_vote_md5_array)
    update_touch_run_id_with_array(Sba_List_Raw_Activities, raw_activities_md5_array)
  end

  def update_touch_run_id_with_array(model, array)
    model.where(:md5_hash => array).update_all(:touched_run_id => run_id) unless array.empty?
  end

  def delete_using_touch_id
    Sba_List_Raw_Senate_Person.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    Sba_List_Scorecard_Raw_Person.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    Sba_List_Raw_House_Person.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    Sba_List_Raw_Score_Votes.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    Sba_List_Raw_Activities.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def finish
    @run_object.finish
  end
end
