require_relative '../models/us_dept_republicans_energy_and_commerce'
require_relative '../models/us_dept_republicans_energy_and_commerce_runs'

class Keeper < Hamster::Keeper
  def add_run(status)
    Usreac_runs.insert({status: status, created_by: 'Igor Sas'})
  ensure
    Hamster.close_connection(Usreac_runs)
  end

  def update_run(status)
    Usreac_runs.last.update({status: status})
  ensure
    Hamster.close_connection(Usreac_runs)
  end

  def add_info(h, index)
    check = Usreac.where("link = '#{h[:link]}'").to_a
    if check.blank?
      Usreac.insert(h.merge({created_by: 'Igor Sas' }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(Usreac)
  end
end
