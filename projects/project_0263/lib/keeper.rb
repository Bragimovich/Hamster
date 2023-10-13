require_relative '../models/usda_rural_development'

class Keeper < Hamster::Keeper

  def get_run
    run_id = 1
    run = Usda_rd.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    run_id
  ensure
    Hamster.close_connection(Usda_rd)
  end

  def add_info(h, run_id, index)
    check = Usda_rd.where("link = '#{h[:link]}'").to_a
    if check.blank?
      Usda_rd.insert(h.merge({ run_id: run_id }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(Usda_rd)
  end
end