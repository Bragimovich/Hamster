require_relative '../models/us_dept_cohs'

class Keeper < Hamster::Scraper
  def get_run
    US_cohs.connection
    run_id = 1
    run = US_cohs.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    US_cohs.clear_active_connections!
    run_id
  end

  def add_info(h, run_id, index)
    US_cohs.connection
    check = US_cohs.where("link = '#{h[:link]}'").to_a
    if check.blank?
      US_cohs.insert(h.merge({ run_id: run_id }))
      puts "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      puts "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
    US_cohs.clear_active_connections!
  end
end
