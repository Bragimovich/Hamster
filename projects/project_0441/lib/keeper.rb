require_relative '../models/da_tx_ci'
require_relative '../models/da_tx_cp'
require_relative '../models/da_tx_ca'
require_relative '../models/da_tx_aws'
require_relative '../models/da_tx_rel'
require_relative '../models/da_tx_run'

class Keeper < Hamster::Scraper
  def initialize
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
  end

  def add_run(status)
    DATXRuns.insert({status: status})
  end

  def update_run(status)
    DATXRuns.last.update({status: status})
  end

  def get_run
    DATXRuns.last[:id]
  end

  def add_case_info(case_info, index, run_id)
    url = 'https://courtsportal.dallascounty.org/DALLASPROD/Home/Dashboard/29'
    h = {
      court_id: case_info[:court_id],
      case_id: case_info[:case_id],
      case_name: case_info[:case_name],
      case_filed_date: case_info[:case_filed_date],
      case_type: case_info[:case_type],
      case_description: nil,
      disposition_or_status: case_info[:disposition],
      status_as_of_date: case_info[:case_status],
      judge_name: case_info[:case_judicial_officer],
      data_source_url: url
    }
    md5_hash = Digest::MD5.hexdigest(h.to_s)
    check = DATXInfo.where("case_id = '#{case_info[:case_id]}' and court_id = '#{case_info[:court_id]}'").to_a
    if check.blank?
      DATXInfo.insert(h.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
      logger.info "[#{index}][#{case_info[:case_id]}] INFO ADD IN DATABASE!".green
    else
      check = DATXInfo.where("case_id = '#{case_info[:case_id]}' and court_id = '#{case_info[:court_id]}' and md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        DATXInfo.where("court_id = '#{h[:court_id]}' and case_id = '#{h[:case_id]}'").last.update({deleted: 1, touched_run_id: run_id})
        logger.info "[#{index}][#{case_info[:case_id]}] INFO UPDATE IN DATABASE! deleted = 1".red
        DATXInfo.insert(h.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
        logger.info "[#{index}][#{case_info[:case_id]}] INFO ADD IN DATABASE!".green
      else
        logger.info "[#{index}][#{case_info[:case_id]}] INFO IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def add_parties(parties, run_id)
    url = 'https://courtsportal.dallascounty.org/DALLASPROD/Home/Dashboard/29'
    parties.each do |party|
      h = {
        court_id: party[:court_id],
        case_id: party[:case_id],
        is_lawyer: party[:is_lawyer],
        party_name: party[:party_name][0..253],
        party_type: party[:party_type],
        law_firm: party[:party_law_firm],
        party_address: party[:party_address],
        party_city: party[:party_city],
        party_state: party[:party_state],
        party_zip: party[:party_zip],
        party_description: nil,
        data_source_url: url
      }
      md5_hash = Digest::MD5.hexdigest(h.to_s)
      check = DATXParty.where("md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        DATXParty.insert(h.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
        logger.info "[+] PARTY ADD IN DATABASE!".green
      else
        logger.info "[-] PARTY IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def add_activities(activities, run_id)
    activities.each do |activity|
      links = activity[:links]
      activity_decs = activity[:comment].blank? ? nil : activity[:comment]
      if links.blank?
        h = {
          court_id: activity[:court_id],
          case_id: activity[:case_id],
          activity_date: activity[:date],
          activity_decs: activity_decs,
          activity_type: activity[:type][0..253],
          activity_pdf: nil
        }
      else
        activity_decs = activity_decs[0..253] unless activity_decs.blank?
        h = {
          court_id: activity[:court_id],
          case_id: activity[:case_id],
          activity_date: activity[:date],
          activity_decs: activity[:comment],
          activity_type: activity_decs,
          activity_pdf: activity[:links].join(', ')
        }
      end
      md5_hash = Digest::MD5.hexdigest(h.to_s)
      check = DATXActivities.where("md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        DATXActivities.insert(h.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
        logger.info "[+] ACTIVITY ADD IN DATABASE!".green
      else
        logger.info "[-] ACTIVITY IS ALREADY IN DATABASE!".yellow
      end
      links.each do |link|
        add_aws(link, activity[:case_id], activity[:court_id], 'activity', md5_hash, run_id)
      end
    end
  end

  def add_aws(link, case_id, court_id, source_type, md5_hash_activity, run_id)
    aws_link = save_to_aws(link, case_id)
    return if aws_link.blank?
    h = {
      court_id: court_id,
      case_id: case_id,
      source_type: source_type,
      aws_link: aws_link,
      source_link: link
    }
    md5_hash = Digest::MD5.hexdigest(h.to_s)
    check = DATXAws.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      DATXAws.insert(h.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
      logger.info "[+] PDF ADD IN DATABASE!".green
    else
      logger.info "[-] PDF IS ALREADY IN DATABASE!".yellow
    end
    add_rel(md5_hash_activity, md5_hash)
  end

  def save_to_aws(link, case_id)
    check = DATXAws.where("source_link = '#{link}'").to_a
    if check.blank?
      key_start = "us_courts_73_#{case_id}_"
      cobble = Dasher.new(:using=>:cobble, ssl_verify: false)
      body = cobble.get(link)
      return if cobble.blank?
      file_type = cobble.headers.blank? ? nil : cobble.headers['content-disposition']
      file_name = link[link.index(/[^\/]+?$/), link.length]
      key = key_start + file_name
      if file_type.blank?
        key += '.pdf'
      elsif file_type.include? '.pdf'
        key += '.pdf'
      elsif file_type.include? '.tif'
        key += '.tiff'
      end
      aws_link = @s3.put_file(body, key, metadata={ url: link })
      logger.info "[+] PDF LOAD IN AWS!".green
      aws_link
    else
      aws_link = check[0]['aws_link']
      logger.info "[-] PDF ALREADY IN AWS!".yellow
      aws_link
    end
  end

  def add_rel(md5_hash_activity, md5_hash_aws)
    h = {
      case_activity_md5: md5_hash_activity,
      case_pdf_on_aws_md5: md5_hash_aws
    }
    check = DATXRelations.where("case_activity_md5 = '#{md5_hash_activity}' and case_pdf_on_aws_md5 = '#{md5_hash_aws}'").to_a
    if check.blank?
      DATXRelations.insert(h)
      logger.info "[+] RELATION ADD IN DATABASE!".green
    else
      logger.info "[-] RELATION IS ALREADY IN DATABASE!".yellow
    end
  end
end
