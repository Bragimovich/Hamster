require_relative '../models/us_doj_ocdetf'
require_relative '../models/us_doj_ocdetf_tags'
require_relative '../models/us_doj_ocdetf_tag_article_links'
require_relative '../models/us_doj_ocdetf_bureau_office_article'

class Keeper < Hamster::Scraper
  def get_run
    US_doj.connection
    run_id = 1
    run = US_doj.select('run_id').to_a.last
    run_id = run[:run_id] + 1 unless run.nil?
    US_doj.clear_active_connections!
    run_id
  end

  def add_info(h, run_id, index)
    US_doj.connection
    check = US_doj.where("link = '#{h[:link]}'").to_a
    if check.blank?
      US_doj.insert(h.merge({ run_id: run_id }))
      puts "[#{index}][+] INFO ADD IN DATABASE!".green
    else
      puts "[#{index}][-] INFO IS ALREADY IN DATABASE!".yellow
    end
    US_doj.clear_active_connections!
  end

  def add_office(office, link)
    US_doj_office.connection
    check = US_doj_office.where("article_link = '#{link}' and bureau_office = '#{office}'").to_a
    if check.blank?
      US_doj_office.insert({article_link: link, bureau_office: office})
      puts "[+] OFFICE ADD IN DATABASE!".green
    else
      puts "[-] OFFICE IS ALREADY IN DATABASE!".yellow
    end
    US_doj_office.clear_active_connections!
  end

  def add_tag(tag)
    US_doj_tags.connection
    check = US_doj_tags.where("tag = '#{tag}'").to_a
    if check.blank?
      US_doj_tags.insert({tag: tag})
      puts "[+] TAG ADD IN DATABASE!".green
    else
      puts "[-] TAG IS ALREADY IN DATABASE!".yellow
    end
    US_doj_tags.clear_active_connections!
  end

  def get_tag_id(tag)
    US_doj_tags.connection
    id = US_doj_tags.where("tag = '#{tag}'").last[:id]
    US_doj_tags.clear_active_connections!
    id
  end

  def add_rel(id, link)
    US_doj_tag_article.connection
    check = US_doj_tag_article.where("article_link = '#{link}' and tag_id = '#{id}'").to_a
    if check.blank?
      US_doj_tag_article.insert({article_link: link, tag_id: id})
      puts "[+] RELATIVE ADD IN DATABASE!".green
    else
      puts "[-] RELATIVE IS ALREADY IN DATABASE!".yellow
    end
    US_doj_tag_article.clear_active_connections!
  end
end


