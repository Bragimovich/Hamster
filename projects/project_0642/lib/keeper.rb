# frozen_string_literal: true

require_relative '../models/ia_court__iacourtcommissions_org'
require_relative '../models/ia_court__iacourtcommissions_org_runs'

class Keeper
  attr_reader :run_id, :run_object

  def initialize
    @run_object = safe_operation(IaCourtOrgRuns) { |model| RunId.new(model) }
    @run_id = safe_operation(IaCourtOrg) { run_object.run_id }
  end

  def store_data(data_hash)
    safe_operation(IaCourtOrg) do |model|
      record = model.find_by(md5_hash: data_hash[:md5_hash])
      if record.nil?
        data_hash.merge!(run_id: run_id, touched_run_id: run_id)
        IaCourtOrg.create data_hash
      else
        record.update!(touched_run_id: run_id, deleted: false)
      end
    end
  end

  def update_delete_status
    safe_operation(IaCourtOrg) { |model| model.where(deleted: 0).where.not(touched_run_id: run_id).update_all(deleted: 1) }
  end

  def finish
    safe_operation(IaCourtOrgRuns) { run_object.finish }
  end

  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        Hamster.logger.error(e.class)
        Hamster.logger.error("Reconnect!")
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
