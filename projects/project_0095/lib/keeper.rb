require_relative '../models/us_sec'
require_relative '../models/us_sec_runs'

class Keeper < Hamster::Keeper
  def add_run(status)
    USSECRuns.insert({status: status, created_by: 'Igor Sas'})
  ensure
    Hamster.close_connection(USSECRuns)
  end

  def update_run(status)
    USSECRuns.last.update({status: status})
  ensure
    Hamster.close_connection(USSECRuns)
  end

  def get_run
    USSECRuns.last[:id]
  ensure
    Hamster.close_connection(USSECRuns)
  end

  def add_info(h, run_id, index)
    check = USSEC.where("release_no = '#{h[:release_no]}'").to_a
    if check.blank?
      USSEC.insert(h.merge({created_by: 'Igor Sas', run_id: run_id }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(USSEC)
  end
end
