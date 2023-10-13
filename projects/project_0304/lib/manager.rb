require_relative '../lib/parser'
require_relative '../lib/scraper'
require_relative "../lib/keeper"

class Manager < Hamster::Harvester

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    main_page = scraper.landing_request
    save_file("#{keeper.run_id}", main_page.body, "main_page")
    main_page_parsing = parser.parsing_html(main_page.body)
    getting_links = parser.get_links(main_page_parsing)
    getting_links.each_with_index do |each_link, idx|
      hurricane_claimsData =scraper.getting_request(each_link)
      hurricane_parsing = parser.parsing_html(hurricane_claimsData.body)
      hurricane_name = parser.hurricane_names(hurricane_parsing, idx)
      save_file("#{keeper.run_id}/hurricane_data", hurricane_claimsData.body, hurricane_name)
    end
  end

  def store
    main_page_list = peon.list(subfolder: "#{keeper.run_id}")
    main_page_list.each do |gz_file|
      if gz_file == "main_page.gz"
        content = peon.give(subfolder: "#{keeper.run_id}", file: gz_file)
        page = parser.parsing_html(content)
        hurricane_name = parser.get_names(page)
        data_array = parser.insurance_hurricanes(hurricane_name, keeper.run_id)
        keeper.insert_records('hurricanes', data_array)
      else
        all_hurricanes = peon.list(subfolder: "#{keeper.run_id}/hurricane_data").sort
        process_business_categories(all_hurricanes)
        process_hurricane_data_categories(all_hurricanes)
        process_counties(all_hurricanes)
        process_insurance_county_data(all_hurricanes)
        process_state_data(all_hurricanes)
      end
    end
    keeper.finish
  end

  private
  attr_accessor :keeper, :parser, :scraper, :insuranceCounties_ids, :dataCategories_ids, :hurricanes_ids, :business_categories

  def process_counties(all_hurricanes)
    all_hurricanes.each_with_index do |hurricane, hurricane_index|
      page, url = base_details(hurricane)
      data_array = parser.insurance_counties(page, keeper.run_id, url)
      keeper.insert_records('InsuranceCounties', data_array)
    end
  end

  def process_insurance_county_data(all_hurricanes)
    county_ids = keeper.insuranceCounties_fetchId('InsuranceCounties')
    category_ids = keeper.dataCategories_fetchId('DataCategories')
    all_hurricanes.each_with_index do |hurricane, hurricane_index|
      page, url = base_details(hurricane)
      hurricane_id = get_hurricane_id(hurricane)
      data_array = parser.county_data(page, hurricane_id, county_ids, category_ids, keeper.run_id, url)
      keeper.insert_records('InsuranceCountyData', data_array)
    end
  end

  def process_hurricane_data_categories(all_hurricanes)
    all_hurricanes.each_with_index do |hurricane, hurricane_index|
      page, url = base_details(hurricane)
      data_array = parser.data_categories(page, keeper.run_id, url)
      keeper.insert_records('DataCategories', data_array)
    end
  end

  def process_state_data(all_hurricanes)
    business_categ_ids = keeper.fetch_businesses('business_categories')
    category_ids = keeper.dataCategories_fetchId('DataCategories')
    all_hurricanes.each_with_index do |hurricane, hurricane_index|
      page, url = base_details(hurricane)
      hurricane_id = get_hurricane_id(hurricane)
      data_array = parser.state_data(page, hurricane_id, category_ids, business_categ_ids, keeper.run_id, url)
      keeper.insert_records('InsuranceStateData', data_array)
    end
  end

  def process_business_categories(all_hurricanes)
    outer_id = 1
    all_hurricanes.each_with_index do |hurricane, hurricane_index|
      page, url = base_details(hurricane)
      all_categories = parser.get_business_categories(page)
      is_parent, category_name = parser.business_name(all_categories.first)
      all_categories = all_categories.reverse if is_parent == 0
      all_categories.each_with_index do |category, category_index|
        is_parent, category_name = parser.business_name(category)
        outer_id = process_business_entity(is_parent, category_name, outer_id, url, all_categories)
      end
    end
  end

  def process_business_entity(is_parent, category_name, outer_id,  url, all_categories)
    if is_parent == 1
      unless keeper.parent_record_exists?('business_categories', category_name, is_parent) > 0
        business_data = parser.business_category_data(outer_id, category_name, is_parent, url, keeper.run_id)
        keeper.insert_business_category("business_categories", business_data, is_parent)
        outer_id += 1
      end
    else
      parent_name = parser.fetch_parent_name(all_categories, category_name)
      unless parent_name == ''
        return outer_id if keeper.parent_record_exists?('business_categories', category_name, is_parent) > 0
        db_id = keeper.fetch_parent_id('business_categories', parent_name)
        category_id = create_child_id(db_id)
        business_data = parser.business_category_data(category_id, category_name, is_parent, url, keeper.run_id)
        keeper.insert_business_category("business_categories", business_data, is_parent)
      else
        return outer_id if keeper.parent_record_exists?('business_categories', category_name, is_parent) > 0
      end
    end
    outer_id
  end

  def create_child_id(db_id)
    (db_id.to_f + 0.1).round(1).to_s
  end

  def base_details(hurricane)
    html = peon.give(subfolder: "#{keeper.run_id}/hurricane_data", file: hurricane)
    page = parser.parsing_html(html)
    url = parser.get_url(page)
    [page, url]
  end

  def get_hurricane_id(hurricane)
    hurricane_name =  hurricane.split("_")[1]
    keeper.fetch_hurricane_id('hurricanes', hurricane_name)
  end

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end
end
