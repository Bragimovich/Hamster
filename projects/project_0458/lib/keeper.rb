require_relative '../models/ctoac'
require_relative '../models/ctoac_runs'

class Keeper < Hamster::Scraper

  def add_run(status)
    CTOACRuns.connection
    CTOACRuns.insert({status: status})
    CTOACRuns.clear_active_connections!
  end

  def update_run(status)
    CTOACRuns.connection
    CTOACRuns.last.update({status: status})
    CTOACRuns.clear_active_connections!
  end

  def get_run
    CTOACRuns.connection
    run_id = CTOACRuns.last[:id]
    CTOACRuns.clear_active_connections!
    run_id
  end

  def add_info(info, index, run_id)
    md5_hash = Digest::MD5.hexdigest(info.to_s)
    CTOAC.connection
    check = CTOAC.where("link = '#{info[:link]}'").to_a
    if check.blank?
      CTOAC.insert(info.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id }))
      puts "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      puts "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
    CTOAC.clear_active_connections!
  end
end
