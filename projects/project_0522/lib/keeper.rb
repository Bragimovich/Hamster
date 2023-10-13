require_relative '../models/ms_saac_case_additional_info'
require_relative '../models/ms_saac_case_activities'
require_relative '../models/ms_saac_case_party'
require_relative '../models/ms_saac_case_pdfs_on_aws'
require_relative '../models/ms_saac_case_relations_activity_pdf'
require_relative '../models/ms_saac_case_relations_info_pdf'
require_relative '../models/ms_saac_case_info'
require_relative '../models/ms_saac_case_runs'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = safe_operation(MsSaacCaseRuns) { |model| RunId.new(model) }
    @run_id = safe_operation(MsSaacCaseRuns) { @run_object.run_id }
  end

  def store_data(data, model)
    array_hashes = data.is_a?(Array) ? data : [data]
    safe_operation(model) do |model_s|
      array_hashes.each do |hash|
        hash = add_md5_hash(hash)
        find_dig = model_s.find_by(md5_hash: hash[:md5_hash])
        if find_dig.nil?
          model_s.store(hash.merge(run_id: @run_id, touched_run_id: @run_id))
        else
          model_s.update(find_dig.id, touched_run_id: @run_id)
        end
      end
    end
  end

  def update_delete_status(model)
    safe_operation(model) { |model_s| model_s.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1) }
  end

  def get_inserted_pdfs
    safe_operation(MsSaacCasePdfsOnAws) { |model| model.where(deleted: 0).pluck(:source_link, :aws_link).to_h }
  end

  def get_case(court_id, case_id)
    MsSaacCaseInfo.find_by court_id: court_id, case_id: case_id, deleted: 0
  end

  def add_md5_hash(data_hash, result: 'full')
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md_5 = Digest::MD5.hexdigest(data_string)
    return md_5 if result == 'only_md_5'
    data_hash.merge(md5_hash: md_5)
  end

  def finish
    safe_operation(MsSaacCaseRuns) { @run_object.finish }
  end

  def mark_as_started_download
    safe_operation(MsSaacCaseRuns) { @run_object.status = 'download started' }
  end

  def mark_as_finished_download
    safe_operation(MsSaacCaseRuns) { @run_object.status = 'download finished' }
  end

  def mark_as_started_store
    safe_operation(MsSaacCaseRuns) do |model|
      if @run_object.status == 'download finished'
        @run_object.status =  'store started'
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
        model.connection.reconnect!
        Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Keeper: Reconnecting...")
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
