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
    @aws_s3   = AwsS3.new(bucket_key = :hamster, account=:hamster)
  end

  def run
    keeper.download_status == 'finish' ? store : download
  end
  
  def download
    already_download_files = peon.list(subfolder: "#{run_id}/") rescue []
    search_page = scraper.connect_search_page
    parsed_page = parser.parsing_html(search_page.body)
    save_file("#{run_id}/", search_page.body, "outer_page")
    all_links   = parser.get_links(parsed_page)
    all_links.each do |link|
      file_name = parser.link_md5(link)
      next if already_download_files.include? file_name +".gz"
      inner_page = scraper.connect_link(link)
      document = parser.parsing_html(inner_page.body)
      save_file("#{run_id}/", inner_page.body, file_name.to_s)
    end 
    keeper.finish_download
    store
  end

  def store
    outer_page  = peon.give(subfolder: "#{run_id}/", file: "outer_page.gz")
    parsed_page = parser.parsing_html(outer_page)
    all_links   = parser.get_links(parsed_page)
    process_links(all_links)
    if keeper.download_status == 'finish'
      keeper.marked_deleted
      keeper.finish
    end
  end

  private

  attr_accessor :keeper, :parser , :scraper , :run_id

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end

  def store_to_aws(link)
    aws_url =  "https://hamster-storage1.s3.amazonaws.com/"
    name = Digest::MD5.new.hexdigest(link)
    key = "crimes_mugshots/NM/#{name}.jpg"
    return (aws_url + key) unless  @aws_s3.find_files_in_s3(key).empty?
    body = link
    @aws_s3.put_file(body, key)
  end

  def process_links(all_links)
    all_links.each do |link|
      file_name = parser.link_md5(link)
      page =  peon.give(subfolder: "#{run_id}/", file: "#{file_name}.gz") rescue nil
      next if page.nil?
      document = parser.parsing_html(page)
      inmate_id = inmate_fun(document, link)
      inmate_ids_id = inmate_ids_fun(document, inmate_id, link)
      arrest_id = arrest_fun(document, inmate_id, link)
      inmate_ids_additional_fun(document, inmate_ids_id, link)
      charges_fun(document, arrest_id, link)
      bond_fun(document, arrest_id, link)
      mugshot_fun(document, inmate_id, link)
      court_hearing_fun(document, arrest_id, link)
      inmate_addresses_fun(document, inmate_id, link)
    end
  end

  def add_charge_id(data, run_id, link, arrest_id = nil)
    new_data_array = []
    
    data.each do |item|
      if arrest_id.nil?
        charge_id = keeper.fetch_charge_id(item[:number], item[:arrest_id])
        new_data_array << parser.add_charge_id(charge_id, item.except(:number), run_id, link)
      else
        charge_id = keeper.fetch_charge_id(item[:case_number], arrest_id)
        new_data_array << parser.add_charge_id(charge_id, item, run_id, link)
      end
    end
    new_data_array
  end

  def inmate_fun(document, link)
    inmates_data = parser.get_inmates(document, run_id, link) 
    keeper.insert_return_id("inmates", inmates_data)
  end

  def inmate_ids_fun(document, inmate_id, link)
    inmates_ids_data  = parser.get_inmate_ids(document, inmate_id, run_id, link)
    keeper.insert_return_id("inmates_ids", inmates_ids_data)
  end

  def arrest_fun(document, inmate_id, link)
    arrest_data = parser.get_arrest_data(document, inmate_id, run_id, link)
    keeper.insert_return_id("arrest", arrest_data)
  end

  def inmate_ids_additional_fun(document, inmate_ids_id, link)
    inmate_ids_additional_data = parser.get_inmate_ids_additional_data(document, inmate_ids_id, run_id, link)
    keeper.insert_record("inmate_ids_additional", inmate_ids_additional_data)
  end

  def charges_fun(document, arrest_id, link)
    charges_data = parser.get_charges_data(document, arrest_id, run_id, link)
    keeper.insert_record("charges", charges_data)
  end

  def bond_fun(document, arrest_id, link)
    bond_data = parser.get_bond_data(document, arrest_id)
    bond_data = add_charge_id(bond_data, run_id, link) unless bond_data.nil?
    keeper.insert_record("bonds", bond_data) unless bond_data.nil?
  end

  def mugshot_fun(document, inmate_id, link)
    mugshot_body = parser.get_mugshot_link(document)
    aws_link  = store_to_aws(mugshot_body)
    mugshot_data = parser.get_mugshot_data(aws_link, run_id, inmate_id, link)
    keeper.insert_record("mugshot", [mugshot_data]) 
  end

  def court_hearing_fun(document, arrest_id, link)
    court_hearings_data = parser.get_court_hearings_data(document)
    court_hearings_data = add_charge_id(court_hearings_data, run_id, link, arrest_id) unless court_hearings_data.nil?
    keeper.insert_record("court", court_hearings_data) unless court_hearings_data.nil?
  end

  def inmate_addresses_fun(document, inmate_id, link)
    inmate_addresses_data = parser.get_inmate_addresses_data(document, inmate_id, run_id, link)
    keeper.insert_record("address", inmate_addresses_data) unless inmate_addresses_data.nil?
  end

end
