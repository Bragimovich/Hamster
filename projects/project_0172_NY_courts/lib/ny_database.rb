# frozen_string_literal: true

def put_all_in_db(case_detail, activities, relations, run_id=1)
  info = case_detail.case_info
  case_id = info[:case_id]
  info.merge!(existed_info(info,run_id)) unless info.empty?
  judgments = case_detail.case_judgement
  judgments = existed_judgments(judgments, case_id, run_id) unless judgments.empty?
  parties = case_detail.case_parties
  parties = existed_parties(parties, case_id, run_id) unless parties.empty?
  activities = existed_parties(activities, case_id, run_id) unless activities.empty?
  begin
    NYCaseInfo.insert(info)
    NYCaseJudgement.insert_all(judgments)      unless judgments.empty?
    NYCaseActivities.insert_all(activities)    unless activities.empty?
    NYCaseParty.insert_all(parties)            unless parties.empty?
    NYCaseRelationsActivity.insert_all(relations) unless relations.empty?
    #NYCaseLawyer.insert_all(lawyers)           unless lawyers.empty?
    mark_deleted_by_md5_hash(info=info, parties=parties, activities=activities, judgments=judgments)
  rescue => e
    Hamster.logger.error e
    NYCaseInfo.where(case_id:case_id).destroy_all
    NYCaseActivities.where(case_id:case_id).destroy_all
    NYCaseLawyer.where(case_number:case_id).destroy_all
    NYCaseParty.where(case_id:case_id).destroy_all
    NYCaseJudgement.where(case_id:case_id).destroy_all
  end
end

def mark_deleted_by_md5_hash(info, parties, activities, judgments)
  case_id = info[:case_id]
  court_id = info[:court_id]
  NYCaseInfo.where(court_id:court_id).where(case_id:case_id).where.not(md5_hash:info[:md5_hash]).update_all(deleted:1)

  parties_md5_hash = parties.map { |party| party[:md5_hash] }
  NYCaseParty.where(court_id:court_id).where(case_id:case_id).where.not(md5_hash:parties_md5_hash).update_all(deleted:1)

  activities_md5_hash = activities.map { |act| act[:md5_hash] }
  NYCaseActivities.where(court_id:court_id).where(case_id:case_id).where.not(md5_hash:activities_md5_hash).update_all(deleted:1)

  judgments_md5_hash = judgments.map { |judgm| judgm[:md5_hash] }
  NYCaseJudgement.where(court_id:court_id).where(case_id:case_id).where.not(md5_hash:judgments_md5_hash).update_all(deleted:1)
end

def put_amount_in_db(case_detail)
  NYCaseJudgement.insert_all(case_detail.case_judgement)      unless case_detail.case_judgement.empty?
end

def existing_cases_judgement(case_links)
  existing_case_links = []
  NYCaseJudgement.where(data_source_url:case_links).map {|row| existing_case_links.push(row.data_source_url)}
  existing_case_links
end

def existing_cases_info(case_links)
  existing_case_links = []
  NYCaseInfo.where(deleted:0).where(data_source_url:case_links).map {|row| existing_case_links.push(row.data_source_url)}
  existing_case_links
end


def existing_cases(case_ids)
  existing_case_ids = []
  NYCaseInfo.where(case_id:case_ids).where(deleted:0).map {|row| existing_case_ids.push(row.case_id)}
  existing_case_ids
end

def get_existing_dates(court_number)
  court_id = COURTS[court_number][:id]
  filed_date = NYCaseInfo.where(court_id:court_id).group(:case_filed_date).order(:case_filed_date).map {|row| row.case_filed_date}
  filed_date
end

def get_existing_saved_pdfs(case_id, links)
  existing_pds = {}
  NYCasePdfsOnAws.where(source_link:links).map{|pdf| existing_pds[pdf[:source_link]]=pdf[:md5_hash]}
  existing_pds
end

def insert_pdf(pdf_hash)
  NYCasePdfsOnAws.insert(pdf_hash)
end

def insert_relations(relations_activity_pdf)
  NYCaseRelationsActivity.insert(relations_activity_pdf)
end

def existed_info(info, run_id)
  NYCaseInfo.where(case_id:info[:case_id]).where(md5_hash:info[:md5_hash]).update_all("deleted=0, touched_run_id=#{run_id}")
  NYCaseInfo.where(court_id:info[:court_id]).where(case_id:info[:case_id]).where.not(touched_run_id:run_id).update_all(deleted:1)
  {run_id:run_id, touched_run_id:run_id}
end


def existed_judgments(judgments, case_id, run_id)
  md5_hashes = []
  new_judgments = []
  judgments.each do |jgm|
    md5_hashes.push(jgm[:md5_hash])
    new_judgments.push(
      jgm.merge!({run_id:run_id, touched_run_id:run_id})
    )
  end
  court_id = judgments[0][:court_id]
  NYCaseJudgement.where(case_id:case_id).where(md5_hash:md5_hashes).update_all("deleted=0, touched_run_id=#{run_id}")
  # NYCaseJudgement.where(court_id:court_id).where(case_id:case_id).where.not(touched_run_id:run_id).update_all(deleted:1)
  new_judgments
end

def existed_activities(activities, case_id, run_id)
  md5_hashes = []
  new_activities = []
  activities.each do |act|
    md5_hashes.push(act[:md5_hash])
    new_activities.push(
      act.merge!({run_id:run_id, touched_run_id:run_id})
    )
  end
  court_id = activities[0][:court_id]
  NYCaseActivities.where(case_id:case_id).where(md5_hash:md5_hashes).update_all("deleted=0, touched_run_id=#{run_id}")
  #NYCaseActivities.where(court_id:court_id).where(case_id:case_id).where.not(touched_run_id:run_id).update_all(deleted:1)
  new_activities
end


def existed_parties(parties, case_id, run_id)
  md5_hashes = []
  new_parties = []
  parties.each do |party|
    md5_hashes.push(party[:md5_hash])
    new_parties.push(
      party.merge!({run_id:run_id, touched_run_id:run_id})
    )
  end
  court_id = parties[0][:court_id]
  NYCaseParty.where(case_id:case_id).where(md5_hash:md5_hashes).update_all("deleted=0, touched_run_id=#{run_id}")
  #NYCaseParty.where(court_id:court_id).where(case_id:case_id).where.not(touched_run_id:run_id).update_all(deleted:1)
  new_parties
end

def mark_deleted_by_case_id(docket_id)
  NYCaseInfo.where(case_id:docket_id).update_all(deleted:1)
  NYCaseParty.where(case_id:docket_id).update_all(deleted:1)
  NYCaseActivities.where(case_id:docket_id).update_all(deleted:1)
  NYCaseJudgement.where(case_id:docket_id).update_all(deleted:1)
end


def insert_cases_to_index(cases)
  NYCaseIndex.insert_all(cases) unless cases.empty?
end

def last_date_in_index_table(court_id)
  last_date_row = NYCaseIndex.where(court_id:court_id).order(:case_filed_date).last
  if !last_date_row.nil?
    last_date_row.case_filed_date
  else
    nil
  end
end


def reconnect_db
  NYCaseInfo.connection.reconnect!
end