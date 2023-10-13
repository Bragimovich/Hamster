require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = @keeper.run_id
    @aws_s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)
  end

  def run
    (keeper.download_status == "finish") ? store : download
  end

  def download
    folders = peon.list(subfolder: "#{run_id}")[0..-2] rescue []
    alpha_array.each do |f_name|
      next if folders.include?("#{f_name}_")

      process_links(f_name)
      alpha_array.each do |l_name|
        next if folders.include?("#{f_name}_#{l_name}")

        process_links(f_name, l_name)
        alpha_array.each do |f_name_add|
          new_f_name = f_name + f_name_add
          next if folders.include?("#{new_f_name}_#{l_name}")
  
          process_links(new_f_name, l_name)
        end
      end
    end
  
    keeper.finish_download
    store
  end

  def store
    all_folders = peon.list(subfolder: "#{run_id}").sort rescue []
    all_folders.each do |inner_folder|
      all_files = peon.list(subfolder: "#{run_id}/#{inner_folder}").reject{|a| a.include? "contact"}
      all_files.each do |file|
        inner_page = peon.give(subfolder: "#{run_id}/#{inner_folder}", file: file) rescue nil
        next if inner_page.include?("SessionExpired")

        for_contact = file.gsub('.gz',"_contact.gz")
        contact_page = peon.give(subfolder: "#{run_id}/#{inner_folder}", file: for_contact) rescue nil
        parse_data = parser.parse_data(inner_page, contact_page)
        inmate_id = save_as_parent(parse_data[:inmate], "minnesota_inmates")
        insert_with_inmate_ids(parse_data[:inmate_id], inmate_id, "minnesota_inmate_ids")
        insert_minnesota_mugshots(parse_data[:mugshot], inmate_id) unless ((parse_data[:mugshot].empty?) || (parse_data[:mugshot].nil?))
        insert_with_inmate_ids(parse_data[:additional_info], inmate_id, "minnesota_inmate_additional_info") unless (parse_data[:additional_info][:current_location].nil?)
        insert_with_inmate_ids(parse_data[:status], inmate_id, "minnesota_inmate_statuses")
        arrest_id = insert_minnesota_arrests(parse_data[:arrest], inmate_id)
        insert_arrest_additional(parse_data[:arrest_additional], arrest_id) unless ((parse_data[:arrest_additional].empty?) || (parse_data[:arrest_additional].nil?))
        charge_id = insert_minnesota_charges(parse_data[:charges], arrest_id)
        insert_minnesota_court_hearings(parse_data[:court_hearings], charge_id)
        insert_with_arrest_ids(parse_data[:holding_facilities], arrest_id, "minnesota_holding_facilities") unless parse_data[:holding_facilities].empty? 
      end
    end
    if keeper.download_status == "finish"
      keeper.mark_delete
      keeper.finish
    end 
  end

  private
  attr_accessor :parser, :scraper, :keeper, :run_id

  #download methods
  def alpha_array
    ('a'..'z').map(&:to_s)
  end

  def process_links(f_name, l_name = nil)
    get_req_response, updated_cookie, data = requesting(f_name, l_name)
    process_inner_links(data, updated_cookie, f_name, l_name) if data.count < 200
  end

  def requesting(f_name, l_name = '')
    main_page = scraper.fetch_main_page
    document = parser.parse_page(main_page.body)
    token = parser.get_token(document)
    cookie = main_page.headers['set-cookie']
    updated_cookie = cookie.split('SameSite=Lax,')[1..-1].join.squish.gsub(' path=/; HttpOnly','').sub(';','').split.join
    post_req_response = scraper.post_req(updated_cookie, token, f_name, l_name)
    get_req_response = scraper.get_req(updated_cookie)
    data = JSON.parse(get_req_response.body)
    [get_req_response, updated_cookie, data]
  end

  def process_inner_links(search_data, cookie, first_names, last_names = '')
    already_downloaded_files = fetch_downloaded_files
    oids = search_data.map { |hash| hash["OID"].to_s }.map{|e| e unless (already_downloaded_files.include? e)}.reject(&:nil?)
    oids.each do |oid|
      inner_link_page_html = scraper.get_inner_link_page(oid, cookie)
      if inner_link_page_html.body.include? 'SessionExpired'
        cookie = regenerated_cookie(first_names, last_names)
        inner_link_page_html = scraper.get_inner_link_page(oid, cookie)
      end
      phone_detail_page = parser.parse_inner_page(inner_link_page_html)
      save_page(inner_link_page_html, "#{oid.to_s}", "#{run_id}/#{first_names}_#{last_names}")
      unless phone_detail_page.nil? or phone_detail_page.include?"mailto"
        phone_detail_page_html = scraper.get_phone_link_page(phone_detail_page)
        save_page(phone_detail_page_html, "#{oid.to_s}_contact", "#{run_id}/#{first_names}_#{last_names}")
      end
    end
  end

  def fetch_downloaded_files
    peon.list(subfolder: "#{run_id}").map{|e| peon.list(subfolder: "#{run_id}/#{e}").map{|s| s.gsub('.gz','')}}.flatten rescue []
  end

  def regenerated_cookie(first_names, last_names)
    get_req_response, updated_cookie, data = requesting(first_names, last_names)
    updated_cookie
  end

  def save_page(html, file_name, sub_folder)
    peon.put(content: html.body, file: file_name, subfolder: sub_folder)
  end

  #store methods
  def insert_with_inmate_ids(inmate_data, inmate_id, model)
    inmate_data[:inmate_id] = inmate_id
    save_with_foreign_key(inmate_data, model)
  end

  def insert_minnesota_arrests(arrests, inmate_id)
    arrests[:inmate_id] = inmate_id
    save_as_parent(arrests, "minnesota_arrests")
  end

  def insert_arrest_additional(data, arrest_id)
    model = "minnesota_arrests_additional"
    if data.is_a?(Array)
      data.each do |detail|
        arrest_additional_data = {}
        arrest_additional_data[:value] = detail[:value]
        arrest_additional_data[:key] = detail[:key]
        arrest_additional_data[:data_source_url] = detail[:data_source_url]
        arrest_additional_data[:arrest_id] = arrest_id
        save_with_foreign_key(arrest_additional_data, model)
      end
    else
      data[:arrest_id] = arrest_id
      save_with_foreign_key(data, model)
    end
  end

  def insert_with_arrest_ids(data, arrest_id, model)
    data[:arrest_id] = arrest_id
    save_with_foreign_key(data, model)
  end

  def insert_minnesota_charges(arrests, arrest_id)
    arrests[:arrest_id] = arrest_id
    save_as_parent(arrests, "minnesota_charges")
  end

  def insert_minnesota_mugshots(mugshots, inmate_id)
    mugshots[:inmate_id] = inmate_id
    image_link = mugshots[:original_link].split(",").last
    mugshots[:aws_link] = store_to_aws(Base64.decode64(image_link))
    mugshots[:original_link] = mugshots[:data_source_url]
    save_with_foreign_key(mugshots, "minnesota_mugshots")
  end

  def insert_minnesota_court_hearings(court_hearings, charge_id)
    court_hearings.each do |court_hearing|
      court_hearing[:charge_id] = charge_id
      save_with_foreign_key(court_hearing, "minnesota_court_hearings")
    end
  end

  def store_to_aws(body)
    aws_url = "https://hamster-storage1.s3.amazonaws.com/"
    name = Digest::MD5.new.hexdigest(body)
    key = "crimes_mugshots/MN/#{name}.jpg"
    return (aws_url + key) unless  @aws_s3.find_files_in_s3(key).empty?
    @aws_s3.put_file(body, key)
  end

  def save_as_parent(data, model)
    data_source_url = data.delete(:data_source_url) if data.key?(:data_source_url)
    current_status = data.delete(:current_status) if data.key?(:current_status)
    md5_hash = parser.create_md5_hash(data)
    data["data_source_url"] = data_source_url
    data["current_status"] = current_status unless current_status.to_s.empty?
    data = add_run_touchedrun_ids(data)
    keeper.insert_for_foreign_key(data, model, md5_hash)
  end

  def save_with_foreign_key(data, model)
    data_source_url = data.delete(:data_source_url) if data.key?(:data_source_url)
    current_status = data.delete(:current_status) if data.key?(:current_status)
    md5_hash = parser.create_md5_hash(data)
    data["data_source_url"] = data_source_url unless data_source_url.to_s.empty?
    data["current_status"] = current_status unless current_status.to_s.empty?
    data = add_run_touchedrun_ids(data)
    keeper.insert_data(data, model, md5_hash)
  end

  def add_run_touchedrun_ids(data)
    data["run_id"] = run_id
    data["touched_run_id"] = run_id
    data
  end

end
