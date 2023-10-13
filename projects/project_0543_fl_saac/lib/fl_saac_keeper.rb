# frozen_string_literal: true

class KeeperFLSAAC

  def insert_parties_raw(parties)
    FLSAACCasePartiesRaw.insert_all(parties) unless parties.empty?
  end

  def update_run_id_parties_raw(parties_md5_hash, run_id)
    FLSAACCasePartiesRaw.where(md5_hash:parties_md5_hash).update_all("deleted=0, touched_run_id=#{run_id}")
  end

  def mark_deleted_parties_raw(run_id)
    FLSAACCasePartiesRaw.where.not(touched_run_id:run_id).update_all("deleted=1, done=1")
  end

  def parties_raw(offset: 0, limit: 1000, court_id:[310,415,416,417,418,419,420])
    FLSAACCasePartiesRaw.where(deleted:0).where(done:0).where(court_id:court_id).offset(offset).limit(limit)
  end

  def existed_case(court_id:, case_ids:)
    FLSAACCaseInfo.where(deleted:0).where(court_id:court_id).where(case_id:case_ids).where.not(status_as_of_date:'Active').map{|c| c[:case_id]}
  end

  def insert_case(case_record, update: nil)
    FLSAACCaseParty.insert(case_record[:party])                                 unless case_record[:party].nil?
    FLSAACCaseAdditionalInfo.insert_all(case_record[:additional_info])          unless case_record[:additional_info].empty?
    FLSAACCaseActivities.insert_all(case_record[:activities])                   unless case_record[:activities].empty?
    FLSAACCaseRelationsActivityPDF.insert_all(case_record[:relations_activity]) unless case_record[:relations_activity].empty?
    if update.nil?
      FLSAACCaseInfo.where(case_id: case_record[:info][:case_id]).where.not(md5_hash:case_record[:info][:md5_hash]).update_all(deleted:1)
      FLSAACCaseInfo.insert(case_record[:info])
    else
      update_info_table(case_record[:info])
    end
  end

  def self.insert_parties(party)
    FLSAACCaseParty.insert_all(party)
  end

  def self.existed_cases_by_case_id(case_ids:)
    FLSAACCaseInfo.where(deleted:0).where(case_id:case_ids).map{|c| c[:case_id]}
  end

  def update_deleted_case(info, md5_hashes, run_id, update: nil)
    case_id = info[:case_id]
    court_id = info[:court_id]

    FLSAACCaseAdditionalInfo.where(court_id:court_id).where(case_id:case_id).where.not(md5_hash:md5_hashes[:additional_info]).update_all(deleted:1)
    FLSAACCaseAdditionalInfo.where(court_id:court_id).where(case_id:case_id).where(md5_hash:md5_hashes[:additional_info]).update_all("deleted=0, touched_run_id=#{run_id}")

    FLSAACCaseActivities.where(court_id:court_id).where(case_id:case_id).where.not(md5_hash:md5_hashes[:activities]).update_all(deleted:1)
    FLSAACCaseActivities.where(court_id:court_id).where(case_id:case_id).where(md5_hash:md5_hashes[:activities]).update_all("deleted=0, touched_run_id=#{run_id}")

    if update.nil?
      FLSAACCaseInfo.where(court_id:court_id).where(case_id:case_id).where.not(md5_hash:md5_hashes[:info]).update_all(deleted:1)
      FLSAACCaseInfo.where(court_id:court_id).where(case_id:case_id).where(md5_hash:md5_hashes[:info]).update_all("deleted=0, touched_run_id=#{run_id}")
    end

  end

  def get_existing_saved_pdfs(links)
    existing_pds = {}
    FLSAACCasePDFsOnAWS.where(source_link:links).map{|pdf| existing_pds[pdf[:source_link]]=pdf[:md5_hash]}
    existing_pds
  end

  def update_info_table(info)
    cases = FLSAACCaseInfo.where(court_id:info[:court_id]).where(case_id:info[:case_id]).where(deleted:0)
    if cases.first.nil?
      FLSAACCaseInfo.insert(info)
    end
  end

  def insert_pdf(pdf_hash)
    FLSAACCasePDFsOnAWS.insert(pdf_hash)
  end

  def insert_relations(relations_activity_pdf)
    FLSAACCaseRelationsActivityPDF.insert(relations_activity_pdf)
  end

  def close_connection
    FLSAACCasePartiesRaw.connection.close
  end

end
