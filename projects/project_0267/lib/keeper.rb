require_relative '../models/us_dept_republicans_oversight_and_reform'
require_relative '../models/us_dept_republicans_oversight_and_reform_runs'

class Keeper < Hamster::Keeper
  def add_run(status)
    USROARRuns.insert({status: status, created_by: 'Igor Sas'})
  ensure
    Hamster.close_connection(USROARRuns)
  end

  def update_run(status)
    USROARRuns.last.update({status: status})
  ensure
    Hamster.close_connection(USROARRuns)
  end

  def add_info(h, index)
    check = USROAR.where("link = '#{h[:link]}'").to_a
    if check.blank?
      USROAR.insert(h.merge({created_by: 'Igor Sas' }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(USROAR)
  end
end
