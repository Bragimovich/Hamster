# frozen_string_literal: true

def safe_operation(model, retries=10)
  begin
    yield(model) if block_given?
  rescue *CONNECTION_ERROR_CLASSES => e
    begin
      retries -= 1
      raise 'Connection could not be established' if retries.zero?
      logger.warn("#{e.class}#{STARS}Reconnect!#{STARS}")
      sleep 100
      Hamster.report(to: OLEKSII_KUTS, message: "project-#{Hamster::project_number} Keeper: Reconnecting...")
      model.connection.reconnect!
    rescue *CONNECTION_ERROR_CLASSES => e
      retry
    end
  retry
  end
end

def put_all_in_db(case_detail, run_id=nil)
  case_id = case_detail[:info][:case_id]
  md5_hash = case_detail[:info][:md5_hash]

  if run_id.nil?
    safe_operation(ARCaseInfo) { |model| model.insert(case_detail[:info]) }
  else
    safe_operation(ARCaseInfo) { |model| model.where(md5_hash:md5_hash).update({touched_run_id:run_id, deleted:0}) }
  end
  safe_operation(ARCaseParty) { |model| model.insert_all(case_detail[:party]) unless case_detail[:party].empty? }
  safe_operation(ARCaseActivities) { |model| model.insert_all(case_detail[:activities]) unless case_detail[:activities].empty? }
  safe_operation(ARCasePdfsOnAws) { |model| model.insert_all(case_detail[:pdfs_on_aws]) unless case_detail[:pdfs_on_aws].empty? }
  safe_operation(ARCaseRelationsActivityPdf) { |model| model.insert_all(case_detail[:relations_activity_pdf]) unless case_detail[:relations_activity_pdf].empty? }
end

def get_pdf_md5_hash(case_id)
  safe_operation(ARCaseRelationsActivityPdf) { |model| model.where(case_id:case_id).map(&:case_activities_md5) }
end

def mark_deleted(case_id)
  safe_operation(ARCaseInfo) { |model| model.where(case_id:case_id).update_all(deleted:1) }
end

def existing_cases(case_ids)
  safe_operation(ARCaseInfo) { |model| model.where(case_id:case_ids).map(&:case_id) }
end

def existing_md5_hash_cases(case_ids)
  safe_operation(ARCaseInfo) { |model| model.where(case_id:case_ids).map(&:md5_hash) }
end

def cases_to_update(year, month)
  start_date = Date.new(year,month)
  end_date = start_date.next_month.prev_day
  safe_operation(ARCaseInfo) { |model| model.where("case_filed_date between ? and ?", start_date, end_date).map {|row| {case_id: row.case_id} } }
end
