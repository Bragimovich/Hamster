require_relative '../models/us_dept_dos_oirf'
require_relative '../models/us_dept_dos_oirf_tags'
require_relative '../models/us_dept_dos_oirf_tags_article_links'

class Keeper < Hamster::Scraper
  def get_run
    US_oirf.connection
    run_id = 1
    run = US_oirf.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    US_oirf.clear_active_connections!
    run_id
  end

  def add_info(h, run_id, index)
    US_oirf.connection
    check = US_oirf.where("link = '#{h[:link]}'").to_a
    if check.blank?
      US_oirf.insert(h.merge({ run_id: run_id }))
      puts "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      puts "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
    US_oirf.clear_active_connections!
  end

  def add_tag(tag)
    US_oirf_tags.connection
    check = US_oirf_tags.where("tag = '#{tag.gsub("'","\\'")}'").to_a
    if check.blank?
      US_oirf_tags.insert({tag: tag})
      puts "[+] TAG ADD IN DATABASE!".green
    else
      puts "[-] TAG IS ALREADY IN DATABASE!".yellow
    end
    US_oirf_tags.clear_active_connections!
  end

  def get_tag_id(tag)
    US_oirf_tags.connection
    id = US_oirf_tags.where("tag = '#{tag.gsub("'","\\'")}'").last
    id = id[:id] unless id.blank?
    US_oirf_tags.clear_active_connections!
    id
  end

  def add_rel(id, link)
    US_oirf_tag_link.connection
    check = US_oirf_tag_link.where("article_link = '#{link}' and tag_id = '#{id}'").to_a
    if check.blank?
      US_oirf_tag_link.insert({article_link: link, tag_id: id})
      puts "[+] RELATIVE ADD IN DATABASE!".green
    else
      puts "[-] RELATIVE IS ALREADY IN DATABASE!".yellow
    end
    US_oirf_tag_link.clear_active_connections!
  end
end
