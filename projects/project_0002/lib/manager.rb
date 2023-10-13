require_relative "../lib/parser"
require_relative "../lib/keeper"
require_relative "../lib/scraper"

class Manager < Hamster::Harvester

  def initialize
    super
    @keeper  = Keeper.new
    @parser  = Parser.new
    @scraper = Scraper.new
  end

  attr_accessor :keeper, :parser, :scraper

  def run
    (keeper.download_status == 'finish') ? store : download
  end

  def download
    main_page = scraper.fetch_main_page
    body = parser.get_profession(main_page)
    link_last = body[2]
    link_append = linksnumber(link_last)
    link_append.each do |part|
      subs = part.gsub(/-/, "_")
      profession_page_response = scraper.profession_page_html()
      link = parser.get_links(profession_page_response, part)
      download_inner_pages(link, part)
      save_page(profession_page_response, "#{part}_outer_page", "#{keeper.run_id}/#{subs}")
    end
    keeper.finish_download
    store
  end

  def store
    md5_array = []
    all_folders = peon.list(subfolder: "#{keeper.run_id}").sort rescue []
    all_folders.each do |inner_folder|
      next if inner_folder == "000_000_000"
      corpfile = inner_folder.gsub(/_/, "-")
      content = peon.give(subfolder: "#{keeper.run_id}/#{inner_folder}" , file: "#{corpfile}.gz")
      links = parser.get_inside_link(corpfile)
      data_hash= parser.info_parser(content, links, md5_array, keeper.run_id)
      keeper.insert_records(data_hash) unless (data_hash.nil?) || (data_hash.empty?)
    end
    keeper.update_touch_run_id(md5_array)
    keeper.delete_using_touch_id if keeper.download_status == "finish"
    keeper.finish if keeper.download_status == "finish"
  end

  private

  def download_inner_pages(link,link_last)
    file_name = link.split("=").last
    subs = link_last.gsub(/-/, "_")
    info_html = scraper.scrape_inner_page(link)
    save_page(info_html, file_name, "#{keeper.run_id}/#{subs}")
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}" , subfolder: sub_folder
  end

  def linksnumber(link_last)
    link_arr = []
    part1, part2, part3 = link_last.split("-")
    last_parts = part2 + part3
    num = last_parts.to_i
    break_val = "000999999".to_i
    (0..999999).each do |i|
      link_last = 
      num < 10 ? "#{part1}-000-00#{num}" :
      num < 100 ? "#{part1}-000-0#{num}" :
      num < 1000 ? "#{part1}-000-#{num}" :
      num < 10000 ? "#{part1}-00#{num.to_s[0]}-#{num.to_s[1..-1]}" :
      num < 100000 ? "#{part1}-0#{num.to_s[0..1]}-#{num.to_s[2..-1]}" :
      "#{part1}-#{num.to_s[0..2]}-#{num.to_s[3..-1]}"
      break if num == break_val
      link_arr << link_last
      num += 1
    end
    link_arr
  end
end
