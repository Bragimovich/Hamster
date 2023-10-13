require_relative '../models/la_sc_case_additional_info'
require_relative '../models/la_sc_case_activities'
require_relative '../models/la_sc_case_party'
require_relative '../models/la_sc_case_pdfs_on_aws'
require_relative '../models/la_sc_case_relations_activity_pdf'
require_relative '../models/la_sc_case_info'
require_relative '../models/la_sc_case_runs'
require_relative '../models/la_sc_case_relations_info_pdf'

class Keeper

  attr_reader :run_id
  def initialize
    @run_object = safe_operation(LaScCaseRuns) { |model| RunId.new(model) }
    @run_id = safe_operation(LaScCaseRuns) { @run_object.run_id }
  end

  def store_data(data, model, data_source_url = nil)
    array_hashes = data.is_a?(Array) ? data : [data]
    safe_operation(model) do |model_s|
      array_hashes.each do |raw_hash|
        hash = add_md5_hash(raw_hash, model_s)
        hash.merge({data_source_url: data_source_url}) unless data_source_url.nil?
        find_dig = model_s.find_by(md5_hash: hash[:md5_hash])
        if find_dig.nil?
          model_s.store(hash.merge(run_id: @run_id, touched_run_id: @run_id))
        else
          find_dig.update(hash.merge(run_id: @run_id, touched_run_id: @run_id))
        end
      end
    end
  end

  def store_case_info(data)
    array_hashes = data.is_a?(Array) ? data : [data]
    safe_operation(LaScCaseInfo) do |model_s|
      array_hashes.each do |raw_hash|
        hash = add_md5_hash(raw_hash, model_s)
        find_dig = model_s.find_by(court_id: raw_hash[:court_id], case_id: raw_hash[:case_id])
        if find_dig.nil?
          model_s.insert(hash.merge(run_id: @run_id, touched_run_id: @run_id))
        else
          find_dig.update(hash.merge(run_id: @run_id, touched_run_id: @run_id))
        end
      end
    end
  end

  def update_delete_status(*models)
    models.each do |model|
      safe_operation(model) { |model| model.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1) }
    end
  end

  def finish
    safe_operation(LaScCaseRuns) { @run_object.finish }
  end

  def mark_as_started_download
    safe_operation(LaScCaseRuns) { @run_object.status = 'download started' }
  end

  def mark_as_finished_download
    safe_operation(LaScCaseRuns) { @run_object.status = 'download finished' }
  end

  def mark_as_started_store
    safe_operation(LaScCaseRuns) do |model|
      if @run_object.status == 'download finished'
        @run_object.status = 'store started'
       else
         raise "Scrape work is not finished correctly"
       end
    end
  end

  def safe_operation(model) 
    begin
      yield(model) if block_given?
    rescue  ActiveRecord::ConnectionNotEstablished, Mysql2::Error::ConnectionError, 
            ActiveRecord::StatementInvalid, ActiveRecord::LockWaitTimeout => e
      begin
        Hamster.report(to: Manager::FRANK_RAO_ID, message: "project-#{Hamster::project_number} Keeper: Reconnecting...", use: :slack)
        sleep 10
        model.connection.reconnect!
      rescue => e
        Hamster.report(to: Manager::FRANK_RAO_ID, message:  "#{e.class}: #{e.message}\n", use: :slack)
        #retry
      end
    #retry
    end
  end

  def add_md5_hash(data_hash, model)
    md5_rel = {LaScCaseInfo => :info, LaScCaseParty => :party, LaScCaseActivities => :activities, LaScCasePdfsOnAws => :pdfs_on_aws} 

    if md5_rel.has_key?(model)
      md5 = MD5Hash.new(table: md5_rel[model])
      md5_hash = md5.generate(data_hash)
    else
      data_string = data_hash.values.inject('') { |str, val| str += val.to_s }
      md5_hash = Digest::MD5.hexdigest(data_string) 
    end 

    data_hash.merge(md5_hash: md5_hash)
  end

  def refine_additional_info
    LaScCaseAdditionalInfo.all.each do |info|
      items = LaScCaseAdditionalInfo.where('case_id=?', info['case_id'])
      if items.length > 1
        items.each do |item|
          if item[:created_at] < Date.new(2023, 3, 14)
            item.delete
          end
        end
      end
    end
  end

  def refine_additional_info_data_source_url
    LaScCaseAdditionalInfo.where('data_source_url is null').each do |additional_info|
      pdf_on_aws = LaScCasePdfsOnAws.find_by(case_id: additional_info[:case_id])
      if pdf_on_aws && !pdf_on_aws[:source_link].nil?
        additional_info[:data_source_url] = pdf_on_aws[:source_link] 
        additional_info.save!
      end
    end
  end

  def refine_case_party
    LaScCaseParty.all.each do |case_party|
      pdf_on_aws = LaScCasePdfsOnAws.find_by(case_id: case_party[:case_id])
      unless pdf_on_aws[:source_link].nil?
        case_party[:data_source_url] = pdf_on_aws[:source_link] 
        case_party.save
      end
    end
  end

  def refine_party_name_on_case_party
    LaScCaseParty.all.each do |case_party|
      if case_party[:party_name].include?('IN RE:')
        case_party[:party_name] = case_party[:party_name].gsub('IN RE:', '').strip
        case_party.save
      end
    end
  end

  def refine_additional_info_strip_space
    LaScCaseAdditionalInfo.where('true').each do |additional_info|
      unless additional_info['lower_court_name'].nil?
        additional_info['lower_court_name'] = additional_info['lower_court_name'].strip
        additional_info.save
      end      
    end
  end

  def refine_status_as_of_date
    LaScCaseInfo.where('true').each do |case_info|
      unless case_info['status_as_of_date'].nil?
        case_info['status_as_of_date'] = case_info['status_as_of_date'].split('-', 2)[0].strip
        case_info.save
      end      
    end
  end
end
