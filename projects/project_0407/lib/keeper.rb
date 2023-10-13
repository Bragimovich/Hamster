require_relative '../models/il_rel'
require_relative '../models/il_act'
require_relative '../models/il_info'
require_relative '../models/il_add_info'
require_relative '../models/il_party'
require_relative '../models/il_aws'
require_relative '../models/il_runs'

class Keeper < Hamster::Scraper

  def initialize
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
  end

  def add_run(status)
    ILRuns.insert({status: status})
  end

  def update_run(status)
    ILRuns.last.update({status: status})
  end

  def get_run
    run_id = ILRuns.last[:id]
    run_id
  end

  def add_info(info, run_id, index, link)
    md5_hash = Digest::MD5.hexdigest(info.to_s)
    check = ILInfo.where("case_id = \"#{info[:case_id]}\" and court_id = \"#{info[:court_id]}\"").to_a
    if check.blank?
      ILInfo.insert(info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE! #{info[:case_id]}".green
    else
      check = ILInfo.where("case_id = \"#{info[:case_id]}\" and court_id = \"#{info[:court_id]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        ILInfo.where("case_id = \"#{info[:case_id]}\" and court_id = \"#{info[:court_id]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        logger.info "[#{index}][-] OLD INFO DELETED = 1 IN DATABASE!".red
        ILInfo.insert(info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        logger.info "[#{index}][+] INFO ADD IN DATABASE! #{info[:case_id]}".green
      else
        logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE! #{info[:case_id]}".yellow
      end
    end
    add_aws(link, info[:court_id], info[:case_id], md5_hash)
  end

  def add_add_info(add_info, run_id)
    md5_hash = Digest::MD5.hexdigest(add_info.to_s)
    check = ILAddInfo.where("case_id = \"#{add_info[:case_id]}\" and court_id = \"#{add_info[:court_id]}\"").to_a
    if check.blank?
      ILAddInfo.insert(add_info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      logger.info "   [+] ADD INFO ADD IN DATABASE!".green
    else
      check = ILAddInfo.where("case_id = \"#{add_info[:case_id]}\" and court_id = \"#{add_info[:court_id]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        ILAddInfo.where("case_id = \"#{add_info[:case_id]}\" and court_id = \"#{add_info[:court_id]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        logger.info "   [-] OLD ADD INFO DELETED = 1 IN DATABASE!".red
        ILAddInfo.insert(add_info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        logger.info "   [+] ADD INFO ADD IN DATABASE!".green
      else
        logger.info "   [-] ADD INFO IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def add_party(party, run_id)
    md5_hash = Digest::MD5.hexdigest(party.to_s)
    check = ILParty.where("case_id = \"#{party[:case_id]}\" and court_id = \"#{party[:court_id]}\" and party_name = \"#{party[:party_name]}\" and party_type = \"#{party[:party_type]}\"").to_a
    if check.blank?
      ILParty.insert(party.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      logger.info "   [+] PARTY ADD IN DATABASE!".green
    else
      check = ILParty.where("case_id = \"#{party[:case_id]}\" and court_id = \"#{party[:court_id]}\" and party_name = \"#{party[:party_name]}\" and party_type = \"#{party[:party_type]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        ILParty.where("case_id = \"#{party[:case_id]}\" and court_id = \"#{party[:court_id]}\" and party_name = \"#{party[:party_name]}\" and party_type = \"#{party[:party_type]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        logger.info "   [-] OLD PARTY INFO DELETED = 1 IN DATABASE!".red
        ILParty.insert(party.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        logger.info "   [+] PARTY ADD IN DATABASE!".green
      else
        logger.info "   [-] PARTY IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def add_aws(link, court_id, case_id, md5_hash_info)
    aws_link = save_to_aws(link, court_id, case_id)
    h = {
      court_id: court_id,
      case_id: case_id,
      source_type: 'info',
      aws_link: aws_link,
      source_link: link
    }
    md5_hash = Digest::MD5.hexdigest(h.to_s)
    check = IlAws.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      IlAws.insert(h.merge({ md5_hash: md5_hash }))
      logger.info "   [+] PDF ADD IN DATABASE!".green
    else
      logger.info "   [-] PDF IS ALREADY IN DATABASE!".yellow
    end
    add_rel(md5_hash_info, md5_hash)
  end

  def save_to_aws(link, court_id, case_id)
    check = IlAws.where("source_link = \"#{link}\"").to_a
    if check.blank?
      key_start = "us_courts_#{court_id}_#{case_id}_"
      cobble = Dasher.new(:using=>:cobble)
      body = cobble.get(link)
      file_name = link[link.index(/[^\/]+?$/), link.length]
      key = key_start + file_name + '.pdf'
      aws_link = @s3.put_file(body, key, metadata={ url: link })
      logger.info "   [+] PDF LOAD IN AWS!".green
      aws_link
    else
      aws_link = check[0]['aws_link']
      logger.info "   [-] PDF ALREADY IN AWS!".yellow
      aws_link
    end
  end

  def add_rel(md5_hash_info, md5_hash_aws)
    h = {
      case_info_md5: md5_hash_info,
      case_pdf_on_aws_md5: md5_hash_aws
    }
    md5_hash = Digest::MD5.hexdigest(h.to_s)
    check = ILRel.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      ILRel.insert(h.merge({ md5_hash: md5_hash }))
      logger.info "   [+] RELATION ADD IN DATABASE!".green
    else
      logger.info "   [-] RELATION IS ALREADY IN DATABASE!".yellow
    end
  end
end
