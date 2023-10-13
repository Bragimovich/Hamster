require_relative '../models/maac_info'
require_relative '../models/maac_party'
require_relative '../models/maac_activities'
require_relative '../models/maac_aws'
require_relative '../models/maac_relations'
require_relative '../models/maac_runs'
require_relative '../models/maac_add_info'

class Keeper < Hamster::Scraper

  def initialize
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
  end
  def get_closed(case_id)
    closed = MAACInfo.where("case_id like '#{case_id}' and (disposition_or_status like '%closed%' or disposition_or_status like '%disposed%' or disposition_or_status like '%decided%')").select('case_id').to_a
    closed_ids = []
    closed.each do |item|
      closed_ids << item[:case_id]
    end
    closed_ids
  end

  def add_run(status)
    MAACRuns.insert({status: status})
  end

  def update_run(status)
    MAACRuns.last.update({status: status})
  end

  def get_run
    MAACRuns.last[:id]
  end

  def add_info(info, run_id, index)
    md5_hash = Digest::MD5.hexdigest(info.to_s)
    check = MAACInfo.where("case_id = \"#{info[:case_id]}\" and court_id = \"#{info[:court_id]}\"").to_a
    if check.blank?
      MAACInfo.insert(info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE! #{info[:case_id]}".green
    else
      check = MAACInfo.where("case_id = \"#{info[:case_id]}\" and court_id = \"#{info[:court_id]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        MAACInfo.where("case_id = \"#{info[:case_id]}\" and court_id = \"#{info[:court_id]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        logger.info "[#{index}][-] OLD INFO DELETED = 1 IN DATABASE!".red
        MAACInfo.insert(info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        logger.info"[#{index}][+] INFO ADD IN DATABASE! #{info[:case_id]}".green
      else
        logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE! #{info[:case_id]}".yellow
      end
    end
  end

  def add_add_info(add_info, run_id)
    md5_hash = Digest::MD5.hexdigest(add_info.to_s)
    check = MAACAddInfo.where("case_id = \"#{add_info[:case_id]}\" and court_id = \"#{add_info[:court_id]}\" and lower_case_id = \"#{add_info[:lower_case_id]}\"").to_a
    if check.blank?
      MAACAddInfo.insert(add_info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      logger.info "[+] ADD INFO ADD IN DATABASE!".green
    else
      check = MAACAddInfo.where("case_id = \"#{add_info[:case_id]}\" and court_id = \"#{add_info[:court_id]}\" and lower_case_id = \"#{add_info[:lower_case_id]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        MAACAddInfo.where("case_id = \"#{add_info[:case_id]}\" and court_id = \"#{add_info[:court_id]}\" and lower_case_id = \"#{add_info[:lower_case_id]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        logger.info "[-] OLD ADD INFO DELETED = 1 IN DATABASE!".red
        MAACAddInfo.insert(add_info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        logger.info "[+] ADD INFO ADD IN DATABASE!".green
      else
        logger.info "[-] ADD INFO IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def add_activity(activity, run_id)
    md5_hash = Digest::MD5.hexdigest(activity.to_s)
    check = MAACActivities.where("case_id = \"#{activity[:case_id]}\" and court_id = \"#{activity[:court_id]}\" and activity_date = \"#{activity[:activity_date]}\" and activity_desc = \"#{activity[:activity_desc].gsub('"','\"')}\"").to_a
    if check.blank?
      MAACActivities.insert(activity.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      logger.info "[+] ACTIVITY ADD IN DATABASE!".green
    else
      check = MAACActivities.where("case_id = \"#{activity[:case_id]}\" and court_id = \"#{activity[:court_id]}\" and activity_date = \"#{activity[:activity_date]}\" and activity_desc = \"#{activity[:activity_desc].gsub('"','\"')}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        MAACActivities.where("case_id = \"#{activity[:case_id]}\" and court_id = \"#{activity[:court_id]}\" and activity_date = \"#{activity[:activity_date]}\" and activity_desc = \"#{activity[:activity_desc].gsub('"','\"')}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        logger.info "[-] OLD ACTIVITY DELETED = 1 IN DATABASE!".red
        MAACActivities.insert(activity.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        logger.info "[+] ACTIVITY ADD IN DATABASE!".green
      else
        logger.info "[-] ACTIVITY ALREADY IN DATABASE!".yellow
      end
    end
  end

  def add_party(party, run_id)
    md5_hash = Digest::MD5.hexdigest(party.to_s)
    check = MAACParty.where("case_id = \"#{party[:case_id]}\" and court_id = \"#{party[:court_id]}\" and is_lawyer = \"#{party[:is_lawyer]}\" and party_name = \"#{party[:party_name].gsub('"','\"')}\" and party_type = \"#{party[:party_type]}\"").to_a
    if check.blank?
      MAACParty.insert(party.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      logger.info "[+] PARTY ADD IN DATABASE!".green
    else
      check = MAACParty.where("case_id = \"#{party[:case_id]}\" and court_id = \"#{party[:court_id]}\" and is_lawyer = \"#{party[:is_lawyer]}\" and party_name = \"#{party[:party_name].gsub('"','\"')}\" and party_type = \"#{party[:party_type]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        MAACParty.where("case_id = \"#{party[:case_id]}\" and court_id = \"#{party[:court_id]}\" and is_lawyer = \"#{party[:is_lawyer]}\" and party_name = \"#{party[:party_name].gsub('"','\"')}\" and party_type = \"#{party[:party_type]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        logger.info "[-] OLD PARTY DELETED = 1 IN DATABASE!".red
        MAACParty.insert(party.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        logger.info "[+] PARTY ADD IN DATABASE!".green
      else
        logger.info "[-] PARTY ALREADY IN DATABASE!".yellow
      end
    end
  end

  def add_document(document, court_id, case_id, run_id)
    source_link = document[:link]
    aws_link = get_aws_link(source_link)
    aws_link = save_to_aws(source_link, court_id, case_id) if aws_link.blank?
    h = {
      court_id: court_id,
      case_id: case_id,
      source_type: 'activity',
      aws_link: aws_link,
      source_link: source_link
    }
    md5_hash = Digest::MD5.hexdigest(h.to_s)
    check = MAACAws.where("source_link = \"#{source_link}\"").to_a
    if check.blank?
      MAACAws.insert(h.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      logger.info "[+] DOCUMENT ADD IN DATABASE!".green
    else
      logger.info "[-] DOCUMENT ALREADY IN DATABASE!".yellow
    end
    add_relation(md5_hash, source_link)
  end

  def add_relation(case_pdf_on_aws_md5, source_link)
    case_activities_md5 = get_activity_md5(source_link)
    return if case_activities_md5.blank?
    check = MAACRelations.where("case_activities_md5 = \"#{case_activities_md5}\" and case_pdf_on_aws_md5 = \"#{case_pdf_on_aws_md5}\"").to_a
    if check.blank?
      MAACRelations.insert({ case_activities_md5: case_activities_md5, case_pdf_on_aws_md5: case_pdf_on_aws_md5 })
      logger.info "[+] RELATION ADD IN DATABASE!".green
    else
      logger.info "[-] RELATION ALREADY IN DATABASE!".yellow
    end
  end

  def get_activity_md5(source_link)
    md5_hash = MAACActivities.where("file like \"%#{source_link}%\"")
    md5_hash.blank? ? nil : md5_hash.first[:md5_hash]
  end

  def get_aws_link(source_link)
    aws_link = MAACAws.where("source_link = \"#{source_link}\"").first
    aws_link.blank? ? nil : aws_link[:aws_link]
  end

  def save_to_aws(source_link, court_id, case_id)
    key_start = "us_courts_expansion_#{court_id}_#{case_id}_"
    cobble = Dasher.new(:using=>:cobble)
    body = cobble.get(source_link)
    file_name = source_link[source_link.index(/[^\/]+?$/), source_link.length]
    key = key_start + file_name
    @s3.put_file(body, key, metadata={ url: source_link })
  end
end
