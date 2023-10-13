require_relative '../models/ca_calbar_bar'
require_relative '../models/ca_calbar_bar_runs'
class Keeper < Hamster::Scraper

  def add_run(status)
    CACBRuns.insert({status: status})
  end

  def update_run(status)
    CACBRuns.last.update({status: status})
  end

  def get_run
    CACBRuns.last[:id]
  end

  def get_run_status
    CACBRuns.last[:status]
  end

  def add_info(info, run_id, index)
    md5_hash = Digest::MD5.hexdigest(info.to_s)
    check = CACB.where("data_source_url = \"#{info[:data_source_url]}\"").to_a
    if check.blank?
      CACB.insert(info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE! #{info[:bar_number]}".green
    else
      check = CACB.where("data_source_url = \"#{info[:data_source_url]}\" and md5_hash = \"#{md5_hash}\"").to_a
      if check.blank?
        CACB.where("data_source_url = \"#{info[:data_source_url]}\" and deleted = 0").update({deleted: 1, touched_run_id: run_id})
        logger.info "[#{index}][-] OLD INFO DELETED = 1 IN DATABASE!".red
        CACB.insert(info.merge({ run_id: run_id, touched_run_id: run_id, md5_hash: md5_hash }))
        logger.info "[#{index}][+] INFO ADD IN DATABASE! #{info[:bar_number]}".green
      else
        logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE! #{info[:bar_number]}".yellow
      end
    end
  end
end
