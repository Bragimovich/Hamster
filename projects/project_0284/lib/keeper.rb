require_relative '../models/us_ice'
require_relative '../models/us_ice_categories'
require_relative '../models/us_ice_categories_article_links'

class Keeper < Hamster::Keeper

  def get_run
    run_id = 1
    run = US_ice.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    run_id
  ensure
    Hamster.close_connection(US_ice)
  end

  def add_tag(tag)
    check = US_ice_c.where("category = '#{tag}'").to_a
    if check.blank?
      US_ice_c.insert({category: tag})
      logger.info "[+] TAG ADD IN DATABASE!".green
    else
      logger.info "[-] TAG IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(US_ice_c)
  end

  def get_tags
    US_ice_c.select('category', 'id')
  ensure
    Hamster.close_connection(US_ice_c)
  end

  def add_info(h, run_id, index)
    check = US_ice.where("link = '#{h[:link]}'").to_a
    if check.blank?
      US_ice.insert(h.merge({ run_id: run_id }))
      logger.info "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      logger.info "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(US_ice)
  end

  def add_rel(id, link)
    check = US_ice_cl.where("article_link = '#{link}' and category_id = #{id}").to_a
    if check.blank?
      US_ice_cl.insert({article_link: link, category_id: id})
      logger.info "[+] RELATIVE ADD IN DATABASE!".green
    else
      logger.info "[-] RELATIVE IS ALREADY IN DATABASE!".yellow
    end
  ensure
    Hamster.close_connection(US_ice_cl)
  end
end