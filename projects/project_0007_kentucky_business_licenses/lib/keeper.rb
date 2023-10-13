# frozen_string_literal: true
require_relative '../models/kentucky_business_licenses_roles'
require_relative '../models/kentucky_business_licenses'
require_relative '../models/kentucky_business_licenses_runs'

class Keeper

  attr_reader :run_id
  def initialize
    @run_object = RunId.new(KentuckyBusinessLicensesRuns)
    @run_id = @run_object.run_id
  end

  def start_processing_keyword(keyword)
    Hamster.logger.debug "start_processing_keyword(#{keyword})"
    KentuckyBusinessLicensesRuns.find_by(id: @run_id).update(:keyword => keyword)
  end
  
  def current_keyword
    KentuckyBusinessLicensesRuns.find_by(id: @run_id).keyword rescue nil
  end
  def store_data(detail_obj)
    license_data = detail_obj[:general]
    license_data = license_data.slice(*license_data_params)
    license_data["md5_hash"] = get_md5_for_licenses(license_data)
    license_data["touched_run_id"] = @run_id
    license_data["run_id"] = @run_id
    
    KentuckyBusinessLicenses.insert(license_data)
    
    roles_data_arr = detail_obj[:officers]
    (0..roles_data_arr.length)
    roles_data_arr.each_with_index do |role_data, i|
      roles_data_arr[i]["organization_number"] = license_data["organization_number"]
      roles_data_arr[i]["run_id"] = @run_id
      roles_data_arr[i]["touched_run_id"] = @run_id
      roles_data_arr[i]["md5_hash"] = get_md5_for_roles(roles_data_arr[i])
      roles_data_arr[i]["data_source_url"] = license_data["license_url"]
    end
    KentuckyBusinessLicensesRoles.where(organization_number: license_data["organization_number"]).update_all(deleted: 1)
    unless roles_data_arr.empty?
      KentuckyBusinessLicensesRoles.insert_all(roles_data_arr) 
    end
  end

  def update_data(detail_obj)
    license_data = detail_obj[:general]
    license_data = license_data.slice(*license_data_params)
    license_data["md5_hash"] = get_md5_for_licenses(license_data)
    license_data["touched_run_id"] = @run_id
    license_data["run_id"] = @run_id
    
    old_item = KentuckyBusinessLicenses.find_by(organization_number: license_data["organization_number"])
    if old_item
      old_item.update(license_data) rescue nil
    else
      KentuckyBusinessLicenses.insert(license_data)
    end
    
    roles_data_arr = detail_obj[:officers]
    (0..roles_data_arr.length)
    roles_data_arr.each_with_index do |role_data, i|
      roles_data_arr[i]["organization_number"] = license_data["organization_number"]
      roles_data_arr[i]["run_id"] = @run_id
      roles_data_arr[i]["touched_run_id"] = @run_id
      roles_data_arr[i]["md5_hash"] = get_md5_for_roles(roles_data_arr[i])
      roles_data_arr[i]["data_source_url"] = license_data["license_url"]
    end
    KentuckyBusinessLicensesRoles.where(organization_number: license_data["organization_number"]).update_all(deleted: 1)
    unless roles_data_arr.empty?
      KentuckyBusinessLicensesRoles.insert_all(roles_data_arr) 
    end
  end

  def get_md5_for_licenses(data_hash)
    data_hash_sliced = data_hash.slice(
      "organization_number",
      "business_name",
      "is_profit_org",
      "status",
      "standing",
      "state",
      "file_date",
      "principal_office_address",
      "principal_office_city_state_zip",
      "managed_by",
      "company_type",
      "organization_date",
      "last_annual_report",
      "registered_agent",
      "authorized_shares",
      "license_url"
    )
    data_string = data_hash_sliced.values.inject(''){|str, val| str += val.to_s}
    Digest::MD5.hexdigest(data_string)
  end

  def get_md5_for_roles(data)
    data_sliced = data.slice(
      "organization_number", "role", "name", "touched_run_id"
    )
    data_string = data_sliced.values.inject(''){|str, val| str+= val.to_s}
    Digest::MD5.hexdigest(data_string)
  end

  def is_not_stored_license(license_url)
    KentuckyBusinessLicenses.find_by(license_url: license_url).nil?
  end

  def license_data_params
    [ "organization_number",
      "business_name",
      "is_profit_org",
      "status",
      "standing",
      "state",
      "file_date",
      "principal_office_address",
      "principal_office_city_state_zip",
      "managed_by",
      "company_type",
      "organization_date",
      "last_annual_report",
      "registered_agent",
      "authorized_shares",
      "license_url"]
  end

  def finish
    @run_object.finish
  end

end
