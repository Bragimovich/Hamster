require_relative '../models/us_dept_hca_majority'
require_relative '../models/us_dept_hca_minority'

class Keeper < Hamster::Keeper

  def get_run_majority
    run_id = 1
    run = US_hca_ma.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    run_id
  ensure
    Hamster.close_connection(US_hca_ma)
  end

  def get_run_minority
    run_id = 1
    run = US_hca_mi.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    run_id
  ensure
    Hamster.close_connection(US_hca_mi)
  end

  def add_info_majority(h, run_id, index)
    check = US_hca_ma.where("link = '#{h[:link]}'").to_a
    if check.blank?
      US_hca_ma.insert(h.merge({ run_id: run_id }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(US_hca_ma)
  end

  def add_info_minority(h, run_id, index)
    check = US_hca_mi.where("link = '#{h[:link]}'").to_a
    if check.blank?
      US_hca_mi.insert(h.merge({ run_id: run_id }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(US_hca_mi)
  end
end