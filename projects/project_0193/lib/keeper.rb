require_relative '../models/us_dept_sfrc_chair'
require_relative '../models/us_dept_sfrc_ranking'

class Keeper < Hamster::Scraper

  def get_run_ranking
    run_id = 1
    run = US_dc_ranking.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    run_id
  ensure
    Hamster.close_connection(US_dc_ranking)
  end

  def get_run_chair
    run_id = 1
    run = US_dc_chair.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    run_id
  ensure
    Hamster.close_connection(US_dc_chair)
  end

  def add_info_ranking(h, run_id, index)
    check = US_dc_ranking.where("link = '#{h[:link]}'").to_a
    if check.blank?
      US_dc_ranking.insert(h.merge({ run_id: run_id }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(US_dc_ranking)
  end

  def add_info_chair(h, run_id, index)
    check = US_dc_chair.where("link = '#{h[:link]}'").to_a
    if check.blank?
      US_dc_chair.insert(h.merge({ run_id: run_id }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(US_dc_chair)
  end
end