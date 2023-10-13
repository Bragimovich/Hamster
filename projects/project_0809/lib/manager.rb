# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
    @run_id = "#{@keeper.run_id}"
  end

  def run
    (keeper.download_status == "finish") ? store : download
  end

  def download
    scraper = Scraper.new
    response = scraper.get_main_response
    save_file(response.body, "dupages_data", run_id)
    keeper.finish_download
    store
  end

  def store
    @aws_s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)
    folders = peon.list(subfolder: run_id)
    json_page = peon.give(subfolder: run_id, file: "dupages_data.gz") rescue nil
    json_body = JSON.parse(json_page)
    json_body.each do |json|
      detail = parser.parse_data(json)
      inmate_id = save_as_parent(detail["inmates"], "il_dupage_inmates")
      insert_with_inmate_ids(detail["inmate_ids"], inmate_id, "il_dupage_inmate_ids")
      insert_il_dupage_mugshots(detail["mugshots"], inmate_id) unless detail["mugshots"]["original_link"].nil?
      arrest_id = insert_il_dupage_arrests(detail["arrest"], inmate_id)
      unless detail["charges"].empty?
        insert_il_dupage_charges(detail["charges"], arrest_id)
        insert_il_dupage_bonds(detail["bonds"], arrest_id)
        insert_il_dupage_court_hearings(detail["court_hearings"])
      end
      insert_with_inmate_ids(detail["additional_info"], inmate_id, "il_dupage_inmate_additional_info") unless detail["additional_info"].empty?
      insert_hold_info(detail["hold_info"], arrest_id) unless detail["hold_info"].empty?
    end
    keeper.mark_delete
    keeper.finish if (keeper.download_status == "finish")
  end

  private
  attr_accessor :keeper, :parser, :scraper, :run_id

  def insert_with_inmate_ids(inmate_data, inmate_id, model)
    inmate_data["inmate_id"] = inmate_id
    save_with_foreign_key(inmate_data, model)
  end

  def insert_il_dupage_arrests(arrests, inmate_id)
    arrests["inmate_id"] = inmate_id
    save_as_parent(arrests, "il_dupage_arrests")
  end

  def insert_il_dupage_mugshots(mugshots, inmate_id)
    mugshots["inmate_id"] = inmate_id
    mugshots["aws_link"] = store_to_aws(mugshots["original_link"])
    return if mugshots["aws_link"] == ''
    save_with_foreign_key(mugshots, "il_dupage_mugshots")
  end

  def insert_il_dupage_charges(charges, arrest_id)
    charges = charges.map { |hash| hash.merge("arrest_id" => arrest_id) }
    charges.each do |charge|
      save_with_foreign_key(charge, "il_dupage_charges")
    end
  end

  def insert_il_dupage_bonds(bonds, arrest_id)
    bonds.each do |bond|
      bond["arrest_id"] = arrest_id
      bond["charge_id"] = keeper.fetch_case_number_charges(bond["bond_number"])
      save_with_foreign_key(bond, "il_dupage_bonds")
    end
  end

  def insert_il_dupage_court_hearings(court_hearings)
    court_hearings.each do |court_hearing|
      court_hearing["charge_id"] = keeper.fetch_case_number_charges(court_hearing["case_number"])
      court_hearing["court_address_id"] = nil
      save_with_foreign_key(court_hearing, "il_dupage_court_hearings")
    end
  end

  def insert_hold_info(hold_info, arrest_id)
    hold_info = hold_info.map { |hash| hash.merge("arrest_id" => arrest_id) }
    hold_info.each do |info|
      save_with_foreign_key(info, "il_hold_info")
    end
  end

  def save_as_parent(data, model)
    data_source_url = data.delete("data_source_url") if data.key?("data_source_url")
    md5_hash = parser.create_md5_hash(data)
    data["data_source_url"] = data_source_url
    data = add_run_touchedrun_ids(data)
    keeper.insert_for_foreign_key(data, model, md5_hash)
  end
  
  def save_with_foreign_key(data, model)
    data_source_url = data.delete("data_source_url") if data.key?("data_source_url")
    md5_hash = parser.create_md5_hash(data)
    data["data_source_url"] = data_source_url unless data_source_url.to_s.empty?
    data = add_run_touchedrun_ids(data)
    keeper.insert_data(data, model, md5_hash)
  end

  def store_to_aws(aws_link)
    key = Digest::MD5.new.hexdigest(aws_link)
    response = scraper.fetch_image(aws_link)
    @aws_s3.put_file(response.body, "crimes_mugshots/IL/#{key}.jpg")
  end

  def add_run_touchedrun_ids(data)
    data["run_id"] = run_id
    data["touched_run_id"] = run_id
    data
  end

  def save_file(response, file_name, store_location)
    peon.put(content:response, file: file_name, subfolder: store_location)
  end

end
