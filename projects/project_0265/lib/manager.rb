require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper  = Scraper.new
    @run_id = keeper.run_id.to_s
  end

  def run
    keeper.download_status == 'finish' ? store : download
  end

  def download
    download_bills
    download_commeties
    keeper.finish_download
    store
  end

  def store
    store_commeties
    store_bills
    if keeper.download_status == 'finish'
      keeper.finish
    end
  end

  private

  attr_accessor :keeper, :parser, :scraper, :run_id

  def download_bills
    @already_inserted_links = keeper.inserted_links("bills")
    response = scraper.connect_bill_search_get
    page = parser.parsing_html(response.body)
    all_legislatures = parser.get_legislature(page)
    all_legislatures.each_with_index do |legislature, index|
      legislature_value = legislature['value']
      legislature_text = legislature.text.squish
      pp, cookie_value, referer = searching(legislature_value)
      id = referer.split("=").last
      folder_name = set_folder_name(legislature_text)
      total_pages = parser.get_total_pages(pp)
      @already_downloaded_bills = peon.list(subfolder: "#{run_id}/bills/#{folder_name}/").sort rescue []
      page_number = 1
      loop do
        all_links = parser.get_bill_links(pp)
        save_links(all_links, folder_name)
        break if page_number >= total_pages
        legislature = set_value(legislature_text)
        response = scraper.pagination(cookie_value, legislature, page_number, referer, id)
        pp = parser.parsing_html(response.body)
        refere = parser.next_link(pp, index)
        page_number += 1
      end
    end
  end

  def save_links(bill_links, folder_name)
    bill_links.each do |link|
      file_name = parser.link_md5(link)
      next if @already_downloaded_bills.include? "#{file_name}.gz"
      next if @already_inserted_links.include? link
      bill_page = scraper.connect_bill(link)
      save_file("#{run_id}/bills/#{folder_name}/", bill_page.body, file_name.to_s)
    end
  end

  def searching(legislature_value)
    response = scraper.connect_bill_search_get
    page = parser.parsing_html(response.body)
    cookie_value = response.headers['set-cookie']
    view_state, generator, previous_value = parser.get_values(page)
    response = scraper.connect_bill_search_post(cookie_value, previous_value, view_state, generator, legislature_value)
    location = response.headers['location']
    response = scraper.connect_bill_outer(location, cookie_value)
    pp = parser.parsing_html(response.body)
    [pp, cookie_value, location]
  end

  def store_bills
    legislatures  = peon.list(subfolder: "#{run_id}/bills/").sort
    legislatures.each do |legislature|
      md5_bills_array = []
      md5_bills_actions_array = []
      bills = peon.list(subfolder: "#{run_id}/bills/#{legislature}/").sort
      bills.each do |bill|
        bill_data = []
        bill_actions = []
        page = peon.give(subfolder: "#{run_id}/bills/#{legislature}/", file: "#{bill}")
        document = parser.parsing_html(page)
        bill_data << parser.get_bill_data(document, legislature, "#{run_id}")
        bill_actions << parser.get_bill_actions(document, legislature, "#{run_id}")
        md5_bills_array << get_md5(bill_data)
        md5_bills_actions_array << get_md5(bill_actions.flatten)
        bill_data = add_foreign_keys(bill_data)
        keeper.insert_array(bill_data, "bills")
        keeper.insert_array(bill_actions.flatten, "bills_actions")
      end
      legis_session = legislature.split("_").first.gsub(/(\d+)([A-Z]*)/, '\1(\2)')
      if (keeper.download_status == "finish")
        update_bills(md5_bills_array.flatten, "bills", legis_session)
        update_bills(md5_bills_actions_array.flatten, "bills_actions", legis_session)
      end
    end
  end

  def download_commeties
    chambers = ["S","H"]
    already_downloaded_chamber =  peon.list(subfolder: "#{run_id}/comittees/")[0..-2] rescue []
    chambers.each do |chamber|
      already_inserted_links  = chamber == "S" ? keeper.inserted_links("s_committees") : keeper.inserted_links("h_committees")
      next if already_downloaded_chamber.include? chamber

      legis_array, generator_values = get_main_page_data(chamber)
      already_downloaded_legis =  peon.list(subfolder: "#{run_id}/comittees/#{chamber}/")[0..-2] rescue []
      legis_array.each  do |legis|
        next if already_downloaded_legis.include? legis

        main_page, all_links   = get_chamber_links(chamber, generator_values, legis)
        already_downloaded_links = peon.list(subfolder: "#{run_id}/comittees/#{chamber}/#{legis}/")[0..-2] rescue []
        all_links.each do |inner_page_link|
          file_name = parser.link_md5(inner_page_link)
          next if already_inserted_links.include? "https://capitol.texas.gov/Committees/#{inner_page_link}"
          next if already_downloaded_links.include? file_name
          inner_page_response = scraper.scrap_inner_legis_page(inner_page_link)
          save_file("#{run_id}/comittees/#{chamber}/#{legis}/", inner_page_response.body, file_name.to_s)
        end
        save_file("#{run_id}/comittees/#{chamber}/#{legis}/", main_page.body, "outer_Page_#{legis}")
      end
    end
  end

  def store_commeties
    ["S", "H"].each do |legis|
      legislature_pages = peon.list(subfolder: "#{run_id}/comittees/#{legis}/").sort

      legislature_pages.each do |legis_page|
        md5_members_array    = []
        md5_committees_array = []
        committee_id_array   = []
        legislature =
        main_page_file = peon.give(subfolder: "#{run_id}/comittees/#{legis}/#{legis_page}/", file: "outer_Page_#{legis_page}.gz")
        parsed_main_page = parser.parsing_html(main_page_file)
        all_links = parser.get_legis_links(parsed_main_page)

        all_links.each do |link|
          file_name = parser.link_md5(link)
          file = peon.give(file: "#{file_name}.gz", subfolder: "#{run_id}/comittees/#{legis}/#{legis_page}") rescue nil
          next if file.nil?
          data_hash = legis == "S" ? parser.parse_committee_data(file, link, run_id, "senate") : parser.parse_committee_data(file, link, run_id, "housing")

          id = keeper.insert_record(data_hash, "#{legis.downcase}_committees")
          all_data = parser.get_senate_housing_data(file, id, link, run_id)
          keeper.insert_array(all_data, "#{legis.downcase}_committee_members")

          legislature = data_hash["legislature"]
          committee_id_array << id
          md5_committees_array << get_md5(all_data)
          md5_members_array << data_hash["md5_hash"]
        end
        if keeper.download_status == "finish"
          if legis == "S"
            update_bills(md5_committees_array.flatten, "s_committees", legislature)
            update_run_id(md5_members_array, committee_id_array, "s_committee_members")
          else
            update_bills(md5_committees_array.flatten, "h_committees", legislature)
            update_run_id(md5_members_array, committee_id_array, "h_committee_members")
          end
        end
      end
    end
  end

  def get_md5(data_hash)
    data_hash.map{|a| a["md5_hash"]}
  end

  def update_run_id(md5_array, committee_id, key)
    keeper.update_touch_run_id(md5_array, key) unless md5_array.empty?
    keeper.delete_using_touch_id(key, committee_id)
  end

  def update_bills(md5_array, key, legis_session)
    keeper.update_touch_run_id(md5_array, key) unless md5_array.empty?
    keeper.delete_bills(key, legis_session)
  end

  def set_value(legislature)
    legislature_values = []
    legislature = legislature.split("-").first.split("(")
    legislature_values << legislature.first.strip
    legislature_values << legislature.last.gsub(")", '').strip
    legislature_values
  end

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end

  def set_folder_name(legislature)
    legislature.gsub(" ", "").gsub("-", "_").gsub("(", '').gsub(")", '')
  end

  def add_foreign_keys(data_array)
    new_hash_data = []
    data_array.each do |data|
      id_senate = get_foreign_id(data, "senate_committee_link", "s_committees")
      id_house  = get_foreign_id(data, "house_committee_link", "h_committees")
      new_hash_data << parser.add_foreign_ids(data, id_senate, id_house)
    end
    new_hash_data
  end

  def get_foreign_id(data, link_key, table_name)
    link = data[link_key]
    keeper.get_id(table_name, link) unless link.nil?
  end

  def get_main_page_data(chamber)
    main_page_response = scraper.connect_commeties_main_page(chamber)
    parsed_main_page   = parser.parsing_html(main_page_response.body)
    legis_array        = parser.get_legis(parsed_main_page)
    generator_values   = parser.get_legis_generator(parsed_main_page)
    [legis_array, generator_values]
  end

  def get_chamber_links(chamber, generator_values, legis)
    main_page   = scraper.connect_commeties_main_page(chamber, generator_values, legis)
    parsed_page = parser.parsing_html(main_page.body)
    all_links = parser.get_legis_links(parsed_page)
    [main_page, all_links]
  end

end
