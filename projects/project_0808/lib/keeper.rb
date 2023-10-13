# frozen_string_literal: true

require_relative '../models/or_oregon_inmates'
require_relative '../models/or_oregon_inmate_runs'
require_relative '../models/or_oregon_inmate_aliases'
require_relative '../models/or_oregon_inmate_ids'
require_relative '../models/or_oregon_arrests'
require_relative '../models/or_oregon_charges'
require_relative '../models/or_oregon_court_hearings'
require_relative '../models/or_oregon_holding_facilities'
require_relative '../models/or_oregon_mugshots'
require_relative '../models/or_oregon_inmate_additional_info'
require_relative '../models/or_oregon_inmate_statuses'
require_relative '../models/or_oregon_aliases_additional'
require_relative '../models/or_oregon_charges_additional'

class Keeper < Hamster::Harvester
  KEYS_ALIASE_HASH = [ 'full_name', 'first_name', 'middle_name', 'last_name', 'suffix', 'data_source_url' ]
  KEYS_ADDITIONAL_HASH = [ 'key', 'value', 'data_source_url' ]
  KEYS_CHARGES_HASH = [ 'number', 'disposition', 'disposition_date', 'description', 'offense_type',
                        'offense_date', 'offense_time', 'crime_class', 'docket_number', 'data_source_url' ]
  KEYS_HOLDING_HASH = [ 'start_date', 'planned_release_date', 'actual_release_date', 'max_release_date', 'total_time', 'data_source_url' ]
  KEYS_HEARING_HASH = [ 'case_number', 'case_type', 'sentence_type', 'min_release_date', 'max_release_date', 'data_source_url' ]
  MD5_ARRAYS =  [ @inmate_info_md5_array = [], @inmate_ids_md5_array = [], @mugshots_md5_array = [],
                  @additional_info_md5_array = [], @status_md5_array = [], @aliase_md5_array = [], 
                  @aliase_additional_md5_array = [], @inmate_arrest_md5_array = [], @charge_md5_array = [], 
                  @charge_additional_md5_array = [], @holding_md5_array = [], @hearing_md5_array = [] ]
  TABLES_MODEL =  [ OrOregonInmates, OrOregonInmateIds, OrOregonMugshots, OrOregonInmateAdditionalInfo,
                    OrOregonInmateStatuses, OrOregonInmateAliases, OrOregonAliasesAdditional, OrOregonArrests,
                    OrOregonCharges, OrOregonChargesAdditional,OrOregonHoldingFacilities, OrOregonCourtHearings ]

  def initialize
    super
    @run_object = safe_operation(OrOregonInmateRun) { |model| RunId.new(model) }
    @run_id = safe_operation(OrOregonInmateRun) { @run_object.run_id }
    @s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)
    @models_hash = TABLES_MODEL.zip(MD5_ARRAYS).to_h
  end

  def insert_all_data(data_hash)
    info_hash = data_hash["inmates_info"].first
    info_hash = genrate_md5_and_run_ids(info_hash)
    MD5_ARRAYS[0].push(info_hash["md5_hash"])
    inmate = OrOregonInmates.find_by(md5_hash: info_hash["md5_hash"], deleted: false)
    if inmate.nil?
      OrOregonInmates.insert(info_hash)
      inmate = OrOregonInmates.find_by(md5_hash: info_hash["md5_hash"], deleted: false)
      @inmate_id = inmate.id
      logger.info "*************** Inserted OrOregonInmates Data ***************"
    else
      @inmate_id = inmate.id
      logger.info "*************** GoT Inmate ID ***************"
    end

    inmate_id_hash = data_hash["inmates_ids"].first
    inmate_id_hash["inmate_id"] = inmate_id
    inmate_id_hash = genrate_md5_and_run_ids(inmate_id_hash)
    MD5_ARRAYS[1].push(inmate_id_hash["md5_hash"])
    OrOregonInmateIds.insert(inmate_id_hash)
    logger.info "*************** Inserted OrOregonInmateIds Data ***************"
    
    mugshots_hash = data_hash["inmates_mugshots"].first
    upload_mugshots_to_aws(mugshots_hash)
    mugshots_hash["inmate_id"] = inmate_id
    mugshots_hash = genrate_md5_and_run_ids(mugshots_hash)
    MD5_ARRAYS[2].push(mugshots_hash["md5_hash"])
    OrOregonMugshots.insert(mugshots_hash)
    logger.info "*************** Inserted OrOregonMugshots Data ***************"
    
    additional_info_hash = data_hash["inmates_additional_info"].first
    additional_info_hash["inmate_id"] = inmate_id
    additional_info_hash = genrate_md5_and_run_ids(additional_info_hash)
    MD5_ARRAYS[3].push(additional_info_hash["md5_hash"])
    OrOregonInmateAdditionalInfo.insert(additional_info_hash)
    logger.info "*************** Inserted OrOregonInmateAdditionalInfo Data ***************"
    
    status_hash = data_hash["inmates_status"].first
    status_hash["inmate_id"] = inmate_id
    status_hash = genrate_md5_and_run_ids(status_hash)
    status_hash["date_of_status_change"] = Date.today.to_s 
    MD5_ARRAYS[4].push(status_hash["md5_hash"])
    OrOregonInmateStatuses.insert(status_hash)
    logger.info "*************** Inserted OrOregonInmateStatuses Data ***************"

    data_hash["inmates_aliases"].each do |full_hash|
      aliase_hash = full_hash.select { |key, _value| KEYS_ALIASE_HASH.include?(key) }.to_h
      aliase_hash["inmate_id"] = inmate_id
      aliase_hash = genrate_md5_and_run_ids(aliase_hash)
      MD5_ARRAYS[5].push(aliase_hash["md5_hash"])
      aliase_record = OrOregonInmateAliases.find_by(md5_hash: aliase_hash["md5_hash"], deleted: false)
      if aliase_record.nil?
        OrOregonInmateAliases.insert(aliase_hash)
        aliase_record = OrOregonInmateAliases.find_by(md5_hash: aliase_hash["md5_hash"], deleted: false)
        @aliase_id = aliase_record.id
        logger.info "*************** Inserted OrOregonInmateAliases Data ***************"
      else
        @aliase_id = aliase_record.id
        logger.info "*************** GoT Alias ID ***************"
      end
      
      aliase_additional_hash = full_hash.select { |key, _value| KEYS_ADDITIONAL_HASH.include?(key) }.to_h
      aliase_additional_hash["aliase_id"] = aliase_id
      aliase_additional_hash = genrate_md5_and_run_ids(aliase_additional_hash)
      MD5_ARRAYS[6].push(aliase_additional_hash["md5_hash"])
      OrOregonAliasesAdditional.insert(aliase_additional_hash)
      logger.info "*************** Inserted OrOregonAliasesAdditional Data ***************"
    end
    
    inmate_arrest_hash = data_hash["inmates_arrest"].first
    inmate_arrest_hash["inmate_id"] = inmate_id
    inmate_arrest_hash["status"] = status_hash["status"]
    inmate_arrest_hash = genrate_md5_and_run_ids(inmate_arrest_hash)
    MD5_ARRAYS[7].push(inmate_arrest_hash["md5_hash"])
    arrest_record = OrOregonArrests.find_by(md5_hash: inmate_arrest_hash["md5_hash"], deleted: false)
    if arrest_record.nil?
      OrOregonArrests.insert(inmate_arrest_hash)
      arrest_record = OrOregonArrests.find_by(md5_hash: inmate_arrest_hash["md5_hash"], deleted: false)
      @arrest_id = arrest_record.id
      logger.info "*************** Inserted OrOregonArrests Data ***************"
    else
      @arrest_id = arrest_record.id
      logger.info "*************** GoT Arrest ID ***************"
    end

    data_hash["inmates_charges"].each do |full_hash|
      charge_hash = full_hash.select { |key, _value| KEYS_CHARGES_HASH.include?(key) }.to_h
      charge_hash["number"] = inmate_id_hash["number"]
      charge_hash["arrest_id"] = arrest_id
      charge_hash = genrate_md5_and_run_ids(charge_hash)
      MD5_ARRAYS[8].push(charge_hash["md5_hash"])
      charge_record = OrOregonCharges.find_by(md5_hash: charge_hash["md5_hash"], deleted: false)
      if charge_record.nil?
        OrOregonCharges.insert(charge_hash)
        charge_record = OrOregonCharges.find_by(md5_hash: charge_hash["md5_hash"], deleted: false)
        @charge_id = charge_record.id
        logger.info "*************** Inserted OrOregonCharges Data ***************"
      else
        @charge_id = charge_record.id
        logger.info "*************** GoT Charge ID ***************"
      end
      
      charge_additional_hash = full_hash.select { |key, _value| KEYS_ADDITIONAL_HASH.include?(key) }.to_h
      charge_additional_hash["charge_id"] = charge_id
      charge_additional_hash = genrate_md5_and_run_ids(charge_additional_hash)
      MD5_ARRAYS[9].push(charge_additional_hash["md5_hash"])
      OrOregonChargesAdditional.insert(charge_additional_hash)
      logger.info "*************** Inserted OrOregonChargesAdditional Data ***************"
      
      holding_hash = full_hash.select { |key, _value| KEYS_HOLDING_HASH.include?(key) }.to_h
      holding_hash["arrest_id"] = arrest_id
      holding_hash = genrate_md5_and_run_ids(holding_hash)
      MD5_ARRAYS[10].push(holding_hash["md5_hash"])
      OrOregonHoldingFacilities.insert(holding_hash)
      logger.info "*************** Inserted OrOregonHoldingFacilities Data ***************"
      
      hearing_hash = full_hash.select { |key, _value| KEYS_HEARING_HASH.include?(key) }.to_h
      hearing_hash["charge_id"] = charge_id
      hearing_hash = genrate_md5_and_run_ids(hearing_hash)
      MD5_ARRAYS[11].push(hearing_hash["md5_hash"])
      OrOregonCourtHearings.insert(hearing_hash)
      logger.info "*************** Inserted OrOregonCourtHearings Data ***************"
    end

  end

  def mark_deleted
    models_hash.each do |model, array|
      delete_records(model)
    end
  end

  def update_touch_run_id
    models_hash.each do |model, array|
      update_touch_id(model, array)
      logger.info "#{model} ||| #{array}"
      array.clear
    end
  end
  
  def finish
    safe_operation(OrOregonInmateRun) { @run_object.finish }
  end
  
  attr_reader :run_id, :parser, :inmate_id, :aliase_id, :arrest_id, :charge_id, :models_hash, :s3
  private

  def genrate_md5_and_run_ids(data_hash)
    data_hash["md5_hash"] = Digest::MD5.hexdigest data_hash.values * ""
    data_hash["run_id"] = run_id
    data_hash
  end

  def upload_mugshots_to_aws(mugshots_hash)
    file_name = mugshots_hash["original_link"].split("idno=").last
    key = "inmates/or/task_808/#{file_name}.jpg"
    return unless s3.find_files_in_s3(key).empty?
    content = open(mugshots_hash["original_link"]).read
    logger.info "Uplading mugshot of inmate #{key} to --> AWS"
    s3.put_file(content, key, metadata={})
  end

  def update_touch_id(model, array)
    model.where(:md5_hash => array).update_all(:touched_run_id => run_id)
  end

  def delete_records(model)
    model.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.error "#{e.class}"
        logger.error "#{e.full_message}"
        logger.error "Reconnect!"
        sleep 100
        model.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end
    retry
    end
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end

end
