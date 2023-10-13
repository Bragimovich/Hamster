require_relative '../models/me_sc_caseable'
require_relative '../models/me_sc_case_runs'
require_relative '../models/me_sc_case_activities'
require_relative '../models/me_sc_case_party'
require_relative '../models/me_sc_case_pdfs_on_aws'
require_relative '../models/me_sc_case_relations_activity_pdf'
require_relative '../models/me_sc_case_info'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = safe_operation(MeScCaseRuns) { |model| RunId.new(model) }
    @run_id = safe_operation(MeScCaseRuns) { @run_object.run_id }
  end

  def store_data(data, model)
    safe_operation(model) { |model| model.store_data(run_id, data) }
  end

  def store_info_hash(hash, model)
    safe_operation(model) { |model| model.store_info_hash(run_id, hash) }
  end

  def update_delete_status(*models)
    models.each do |model|
      safe_operation(model) { |model| model.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1) }
    end
  end

  def get_inserted_pdf
    safe_operation(MeScCasePdfsOnAws) { |model| model.where(deleted: 0).pluck(:case_id, :source_link, :aws_link) }
  end

  def get_activity_md5_for(case_id, file, type, date)
    safe_operation(MeScCaseActivities) { |model| model.find_by(case_id: case_id, file: file, activity_type: type, activity_date: date, deleted: 0, touched_run_id: run_id)&.md5_hash }
  end

  def finish
    safe_operation(MeScCaseRuns) { @run_object.finish }
  end

  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        Hamster.logger.error(e.class)
        Hamster.logger.error("Keeper: Reconnecting...\nModel: #{model}")
        Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Keeper: Reconnecting...\nModel: #{model}")
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
