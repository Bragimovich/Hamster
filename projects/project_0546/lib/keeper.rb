require_relative '../models/nm_sc_case_additional_info'
require_relative '../models/nm_sc_case_activities'
require_relative '../models/nm_sc_case_party'
require_relative '../models/nm_sc_case_pdfs_on_aws'
require_relative '../models/nm_sc_case_relations_activity_pdf'
require_relative '../models/nm_sc_case_info'
require_relative '../models/nm_sc_case_runs'
require_relative '../models/nm_sc_case_relations_info_pdf'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = safe_operation(NmScCaseRuns) { |model| RunId.new(model) }
    @run_id = safe_operation(NmScCaseRuns) { @run_object.run_id }
  end

  def store_data(data, model)
    array_hashes = data.is_a?(Array) ? data : [data]

    safe_operation(model) do |model|
      array_hashes.each do |raw_hash|
        hash = add_md5_hash(raw_hash, model)
        find_dig = model.find_by(md5_hash: hash[:md5_hash])
        if find_dig.nil?
          model.store(hash.merge(run_id: @run_id, touched_run_id: @run_id))
        else
          hash.merge!(touched_run_id: @run_id, deleted: false)
          find_dig.update!(hash)
        end
      end
    end
  end

  def store_info_data(info_hash, case_date)
    safe_operation(NmScCaseInfo) do |model|
      hash = add_md5_hash(info_hash, model)
      case_in_db = model.find_by(case_id: hash[:case_id], court_id: hash[:court_id])

      if case_in_db.blank?
        NmScCaseInfo.store(hash.merge(run_id: @run_id, touched_run_id: @run_id))
      else
        case_in_db = model.find_by(case_id: hash[:case_id], court_id: hash[:court_id], deleted: 0)
        
        if case_in_db && case_in_db[:md5_hash] == hash[:md5_hash]
          hash.merge!(touched_run_id: @run_id)
          case_in_db.update!(hash)
        elsif case_in_db

          if check_newer_date(case_date, case_in_db) == true
            case_in_db.update!(deleted: 1)
            NmScCaseParty.where(case_id: hash[:case_id], court_id: hash[:court_id], data_source_url: case_in_db[:data_source_url], deleted: 0).update_all(deleted: 1)
            NmScCaseAdditionalInfo.where(case_id: hash[:case_id], court_id: hash[:court_id], data_source_url: case_in_db[:data_source_url], deleted: 0).update_all(deleted: 1)
            NmScCaseRelationsInfoPdf.where(case_info_md5: case_in_db[:md5_hash], deleted: 0).update_all(deleted: 1)
            NmScCasePdfsOnAws.where(case_id: hash[:case_id], court_id: hash[:court_id], source_link: case_in_db[:data_source_url], source_type: 'info', deleted: 0).update_all(deleted: 1)

            md5_in_db = model.find_by(md5_hash: hash[:md5_hash], deleted: 1)

            if md5_in_db.blank?
              NmScCaseInfo.store(hash.merge(run_id: @run_id, touched_run_id: @run_id))
            else
              hash.merge!(touched_run_id: @run_id, deleted: false)
              md5_in_db.update!(hash)
            end

          else
            return nil
          end
          
        else
          md5_in_db = model.find_by(md5_hash: hash[:md5_hash], deleted: 1)

          if md5_in_db.blank?
            NmScCaseInfo.store(hash.merge(run_id: @run_id, touched_run_id: @run_id))
          else
            hash.merge!(touched_run_id: @run_id, deleted: false)
            md5_in_db.update!(hash)
          end
        end
      end

      hash
    end
  end

  def check_newer_date(new_case_date, old_case)
    default_date = Date.parse('0001-01-01') 
    old_case_date = NmScCaseActivities.find_by(case_id: old_case[:case_id], court_id: old_case[:court_id], data_source_url: old_case[:data_source_url], deleted: 0)[:activity_date]
    old_case_date ||= default_date
    new_case_date = Date.parse(new_case_date) rescue default_date

    new_case_date > old_case_date
  end

  def update_delete_status(*models)
    models.each do |model|
      safe_operation(model) { |model| model.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1) }
    end
  end

  def get_inserted_pdf
    safe_operation(NmScCasePdfsOnAws) { |model| model.where(deleted: 0).pluck(:court_id, :case_id, :source_link, :aws_link) }
  end

  def get_inserted_html
    safe_operation(NmScCasePdfsOnAws) { |model| model.where(deleted: 0).pluck(:court_id, :case_id, :source_link, :aws_html_link) }
  end

  def get_case(court_id, case_id)
    NmScCaseInfo.find_by court_id: court_id, case_id: case_id, deleted: 0
  end

  def add_md5_hash(data_hash, model)
    md5_rel = {NmScCaseInfo => :info, NmScCaseParty => :party, NmScCaseActivities => :activities, NmScCasePdfsOnAws => :pdfs_on_aws} 

    if md5_rel.has_key?(model)
      md5 = MD5Hash.new(table: md5_rel[model])
      md5_hash = md5.generate(data_hash)
    else
      data_string = data_hash.values.inject('') { |str, val| str += val.to_s }
      md5_hash = Digest::MD5.hexdigest(data_string) 
    end 

    data_hash.merge(md5_hash: md5_hash)
  end

  def finish
    safe_operation(NmScCaseRuns) { @run_object.finish }
  end

  def mark_as_started_download
    safe_operation(NmScCaseRuns) { @run_object.status = 'download started' }
  end

  def mark_as_finished_download
    safe_operation(NmScCaseRuns) { @run_object.status = 'download finished' }
  end

  def mark_as_started_store
    safe_operation(NmScCaseRuns) do |model|
      if @run_object.status == 'download finished'
        @run_object.status = 'store started'
       else
         raise "Scrape work is not finished correctly"
       end
    end
  end

  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        Hamster.logger.error(e.class)
        Hamster.logger.error("Keeper: Reconnecting...")
        sleep 100
        Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Keeper: Reconnecting...")
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
