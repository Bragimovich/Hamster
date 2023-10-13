# frozen_string_literal: true
require_relative '../models/mcf_con_csv'
require_relative '../models/mcf_exp_csv'

require_relative '../models/mcf_con_json'
require_relative '../models/mcf_exp_json'
require_relative '../models/mcf_candidate_json'
require_relative '../models/mcf_committee_json'

require_relative '../models/maine_campaign_finance_runs'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(MaineCampaignFinanceRuns)
    @run_id = @run_object.run_id
  end

  def store_contributions_csv(csv_content, year)
    csv = CSV.parse(csv_content, liberal_parsing: true)
    csv_headers = csv[0].map(&:underscore).map{|e| e.split(/\s/).join('_').split("/").join('_')}
    csv_headers = csv_headers.map{|h| con_header_change[h] || h}
    csv[1..].each do |row|
      next if row.length != csv_headers.length
      record = {}
      row.each_with_index do |value, index|
        record[csv_headers[index]] = value
      end
      record["year"] = year
      record["md5_hash"] = get_md5_hash(record)
      Hamster.logger.debug record
      safe_operation(MCFConCsv) { |model| model.insert(record) }
    end
  end

  def store_expenditures_csv(csv_content, year)
    csv = CSV.parse(csv_content, liberal_parsing: true)
    csv_headers = csv[0].map(&:underscore).map{|e| e.split(/\s/).join('_').split("/").join('_')}
    csv_headers = csv_headers.map{|h| exp_csv_params[h] || h}
    csv[1..].each do |row|
      next if row.length != csv_headers.length
      record = {}
      row.each_with_index do |value, index|
        record[csv_headers[index]] = value
      end
      record["year"] = year
      record["md5_hash"] = get_md5_hash(record)
      Hamster.logger.debug record
      safe_operation(MCFExpCsv) { |model| model.insert(record) }
    end
  end

  def store_contributions_json(data)
    data_arr = data
    unless data.kind_of?(Array)
      data_arr = [data]
    end
    data_arr.each do |rec|
      rec_converted = {}
      rec.keys.each do |key| 
        rec_converted[key.underscore] = rec[key]
      end
      rec_converted['md5_hash'] = get_md5_hash(rec_converted)
      safe_operation(MCFConJson) { |model| model.insert(rec_converted) }
    end
  end

  def store_expenditures_json(data)
    data_arr = data
    unless data.kind_of?(Array)
      data_arr = [data]
    end
    data_arr.each do |rec|
      rec_converted = {}
      rec.keys.each do |key| 
        rec_converted[key.underscore] = rec[key]
      end
      rec_converted['md5_hash'] = get_md5_hash(rec_converted)
      safe_operation(MCFExpJson) { |model| model.insert(rec_converted) }
    end
  end

  def store_candidates_json(data)
    data_arr = data
    unless data.kind_of?(Array)
      data_arr = [data]
    end
    data_arr.each do |rec|
      rec_converted = {}
      rec.keys.each do |key| 
        rec_converted[key.underscore] = rec[key]
      end
      rec_converted['md5_hash'] = get_md5_hash(rec_converted)
      safe_operation(MCFCandidateJson) { |model| model.insert(rec_converted) }
    end
  end

  def store_committees_json(data)
    data_arr = data
    unless data.kind_of?(Array)
      data_arr = [data]
    end
    data_arr.each do |rec|
      rec_converted = {}
      rec.keys.each do |key| 
        rec_converted[key.underscore] = rec[key]
      end
      rec_converted['md5_hash'] = get_md5_hash(rec_converted)
      safe_operation(MCFCommitteeJson) { |model| model.insert(rec_converted) }
    end
  end

  def get_md5_hash(data_hash)
    data_string = data_hash.values.inject('') { |str, val| str += val.to_s }
    md5_hash = Digest::MD5.hexdigest(data_string)
  end

  def con_csv_params
    ["org_id", "legacy_id", "committee_name", "candidate_name", "receipt_amount", "receipt_date", "office", "district", "last_name", "first_name", "middle_name", "suffix", "address1", "address2", "city", "state", "zip", "description", "receipt_id", "filed_date", "report_name", "receipt_source_type", "receipt_type", "committee_type", "amended", "employer", "occupation", "occupation_comment", "employment_information_requested", "forgiven_loan", "election_type"]
  end

  def exp_csv_params
    { 
      "first_name" => "payee_first_name",
      "last_name" => "payee_last_name",
      "mi" => "payee_middle_name",
      "filed_date" => "date_filed",
      "purpose" => "expenditure_purpose"
    }
  end

  def con_header_change
    {
      "mi" => "middle_name",
      "employment_info_requested" => "employment_information_requested"
    }
  end

  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        sleep 10
        Hamster.logger.debug 'Connection could not be established'
        # Hamster.report(to: Manager::FRANK_RAO, message: "project-#{Hamster::project_number} Keeper: Reconnecting...")
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

  def finish
    @run_object.finish
  end

end
