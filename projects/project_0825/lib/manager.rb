require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)
    @run_id = @keeper.run_id.to_s
  end

  def scrape
    keeper.mark_delete
    download
    store
  end

  def download
    main_page = scraper.main_page
    cookie = main_page['set-cookie']
    inner_page = scraper.inner_page(cookie, false)
    body_info_array = parser.get_outer_body(inner_page.body)
    page_count = 0
    while true
      inner_page = scraper.inner_page(cookie, true, page_count+=30)
      body_info_array = parser.get_outer_body(inner_page.body)
      files = peon.give_list(subfolder: "#{run_id}/#{data_page}") rescue []
      break if body_info_array.empty?

      file_count = 0
      body_info_array.each do |body|
        data_page = scraper.data_page(body, cookie)
        image_url = parser.image_url(data_page.body)
        image_response = scraper.get_image(image_url) unless image_url.nil?
        save_page(data_page.body, "#{file_count+=1}", "#{run_id}/#{page_count}")
        save_page(image_response.body, "#{file_count}_image", "#{run_id}/#{page_count}") unless image_url.nil?
      end
    end
  end

  def store
    folders = peon.list(subfolder: run_id) rescue []
    folders.each do |folder|
      create_empty_array
      files = peon.give_list(subfolder: "#{run_id}/#{folder}").sort.reject { |e| e.include? 'image'}
      files.each_with_index do |file, index|
        page = peon.give(subfolder: "#{run_id}/#{folder}", file: file)
        inmate_hash, tags = parser.parse(page, run_id)
        inmate_id = keeper.insert_data(inmate_hash, 'NjEssexInmates')
        @mugshot_array << upload_on_aws(file, folder, page, inmate_id)
        store_data(inmate_id, tags)
      end
      store_all_data
    end
    keeper.mark_delete
    keeper.finish
  end

  def create_empty_array
    @additional_info_array = []
    @alias_array = []
    @inmate_ids_array = []
    @holding_facilities_array = []
    @bonds_array = []
    @charges_array = []
    @mugshot_array = []
  end

  def store_all_data
    keeper.store(@additional_info_array, 'NjEssexInmateAdditionalInfo')
    keeper.store(@alias_array.flatten.reject(&:empty?), 'NjEssexInmateAliases') unless @alias_array.empty?
    keeper.store(@inmate_ids_array, 'NjEssexInmateIds')
    keeper.store(@holding_facilities_array, 'NjEssexHoldingFacilities')
    keeper.store(@bonds_array.flatten.reject(&:empty?), 'NjEssexBonds')
    keeper.store(@charges_array.flatten.reject(&:empty?), 'NjEssexCharges')
    keeper.store(@mugshot_array.flatten.reject(&:empty?), 'NjEssexMugshots')
    create_empty_array if @additional_info_array.count > 9
  end

  def store_data(inmate_id, page)
    arrest_hash = parser.get_arrests(page, inmate_id, run_id)
    arrest_id = keeper.insert_data(arrest_hash, 'NjEssexArrests')
    @additional_info_array << parser.get_inmate_additional_info(page, inmate_id, run_id)
    @alias_array << parser.get_alias_array(page, inmate_id, run_id)
    @inmate_ids_array << parser.get_inmates_ids(page, inmate_id, run_id)
    hold_fac_hash = parser.get_holding_facilities_addresses(page, run_id)
    hold_fac_add_id = keeper.insert_data(hold_fac_hash, 'NjEssexHoldingFacilitiesAddresses')
    @holding_facilities_array << parser.get_holding_facilities(page, arrest_id, hold_fac_add_id, run_id)
    @charges_array << parser.get_charges_array(page, arrest_id, run_id)
    @bonds_array << parser.get_bonds_array(page, arrest_id, run_id)
    store_all_data if @additional_info_array.count > 100
  end

  def upload_on_aws(file, folder, html, inmate_id)
    image = peon.give(subfolder: "#{run_id}/#{folder}", file: "#{file.gsub('.gz', '')}_image") rescue nil
    return [] if image.nil?
    image_url = parser.image_url(html)
    name = image_url.split('=').last
    aws_url = upload_mugshots_to_aws(image, name)
    parser.mugshot_hash(image_url, aws_url, inmate_id, run_id)
  end


  def upload_mugshots_to_aws(image, name)
    key = "inmates/nj/essex/#{name}.jpg"
    return "https://hamster-storage1.s3.amazonaws.com/#{key}" unless s3.find_files_in_s3(key).empty?

    s3.put_file(image, key, metadata={})
  end

  def save_page(json, file_name, subfolder)
    peon.put content: json, file: file_name, subfolder: subfolder
  end

  attr_accessor :keeper, :parser, :scraper, :s3, :run_id

end
