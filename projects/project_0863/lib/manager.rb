require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper    = Keeper.new
    @parser    = Parser.new
    @scraper   = Scraper.new
    @subfolder = "Run_Id_#{@keeper.run_id}"
  end

  def run
    (keeper.download_status(keeper.run_id)[0].to_s == "true") ? store : download
  end

  private

  def get_browser_main_page
    @main_page, @captcha_response, @cookie = scraper.get_main_page
  end

  def download
    already_downloaded = peon.list(subfolder: subfolder) rescue []
    get_browser_main_page
    save_file(@main_page, "main_page", subfolder)
    main_page = parser.parse_html(@main_page)
    links = parser.get_links(main_page)
    links.each do |link|
      booking_id = link.split("=").last.squish
      next if already_downloaded.include? booking_id
      get_page, get_page_noko, name_link, charge_links = get_main_page(link)
      if (get_page_noko.text.include? "Failed client authentication.") || (get_page_noko.text.include? "logging in") || (name_link.nil?)
        get_browser_main_page
        get_page, get_page_noko, name_link, charge_links = get_main_page(link)
      end
      file_name = Digest::MD5.hexdigest link
      save_file(get_page.body, file_name, "#{subfolder}/#{booking_id}")
      inner_links(name_link, charge_links, booking_id)
    end
    keeper.mark_download_status(keeper.run_id)
    store if keeper.download_status(keeper.run_id)[0].to_s == "true"
  end

  def get_main_page(link)
    get_page = scraper.get_inner_page(link, @captcha_response, @cookie)
    get_page_noko = parser.parse_html(get_page.body)
    name_link, charge_links = parser.get_inner_links(get_page_noko)
    [get_page, get_page_noko, name_link, charge_links]
  end

  def inner_links(name_link, charge_links, booking_id)
    name_page = scraper.get_inner_page(name_link, @captcha_response, @cookie)
    save_file(name_page.body, "name", "#{subfolder}/#{booking_id}")
    charge_links.each_with_index do |link, index|
      get_page = scraper.get_inner_page(link, @captcha_response, @cookie)
      get_page_noko = parser.parse_html(get_page.body)
      if (get_page_noko.text.include? "Invalid request") || (get_page_noko.text.include? "Failed client authentication.") || (get_page_noko.text.include? "logging in")
        get_browser_main_page
        inner_links(name_link, charge_links, booking_id)
      end
      save_file(get_page.body, "charge_#{index+1}", "#{subfolder}/#{booking_id}")
    end
  end

  def store
    ids = keeper.already_inserted_records
    main_page = peon.give(file: "main_page", subfolder: subfolder)
    main_page = parser.parse_html(main_page)
    links = parser.get_links(main_page)
    links.each do |link|
      booking_id = link.split("=").last.squish
      next if ids.include? booking_id
      file_name = Digest::MD5.hexdigest link
      inner_page = peon.give(file: file_name, subfolder: "#{subfolder}/#{booking_id}")
      inner_page = parser.parse_html(inner_page)
      name_link, charge_links = parser.get_inner_links(inner_page)
      name_page  = peon.give(file: "name", subfolder: "#{subfolder}/#{booking_id}")
      name_page  = parser.parse_html(name_page)
      make_insertions(inner_page, name_page, charge_links, link, booking_id, name_link)
    end
    keeper.marked_deleted
    keeper.finish
  end

  def make_insertions(inner_page, name_page, charge_links, link, booking_id, name_link)
    inmates_data = parser.get_inmates_info(inner_page, name_page, link, keeper.run_id)
    inmate_id    = keeper.insert_for_foreign_key(inmates_data, "inmates")
    arrest_data  = parser.get_arrests_info(inner_page, booking_id, link, keeper.run_id, inmate_id)
    arrest_id    = keeper.insert_for_foreign_key(arrest_data, "arrests")
    charge_links.each_with_index do |charge_link, index|
      charge_page  = peon.give(file: "charge_#{index+1}", subfolder: "#{subfolder}/#{booking_id}")
      charge_page  = parser.parse_html(charge_page)
      next if charge_page.text.include? "Invalid request"
      charges_data = parser.charges_info(charge_page, inner_page, charge_link, link, keeper.run_id, index+1, arrest_id)
      next if charges_data.nil?
      charges_id   = keeper.insert_for_foreign_key(charges_data, "charges")
      keeper.insert_for_foreign_key(parser.court_hearings(charge_page, inner_page, charge_link, link, keeper.run_id, index+1, charges_id), "hearings")
      keeper.insert_for_foreign_key(parser.holding_facilities(inner_page, link, keeper.run_id, index+1, arrest_id), "facilities")
      keeper.insert_for_foreign_key(parser.bonds(inner_page, link, keeper.run_id, index+1, arrest_id, charges_id), "bonds")
    end
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  attr_accessor :parser, :keeper, :subfolder, :scraper
end
