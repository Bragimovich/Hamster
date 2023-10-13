# frozen_string_literal: true

require_relative '../models/ks_court_kscourts_runs'
require_relative '../models/ks_court_kscourts_org'

class Keeper
  def initialize
    @run_object = safe_operation(KSCourtKscourtsRuns) { |model| RunId.new(model) }
    @run_id = safe_operation(KSCourtKscourtsRuns) { @run_object.run_id }
  end

  attr_reader :run_id, :run_object
  attr_writer :run_id

  def store_data(data_hash)
    safe_operation(KSCourtKscourtsOrg) do |model|
      find_dig = model.find_by(md5_hash: data_hash[:md5_hash])
      if find_dig.nil?
        model.store(data_hash)
      else
        model.update(find_dig.id, touched_run_id: @run_id)
      end
    end
  end

  def fetch_db_inserted_md5
    safe_operation(KSCourtKscourtsOrg) { |model| model.pluck(:md5_hash) }
  end

  def update_delete_status
    safe_operation(KSCourtKscourtsOrg) { |model| model.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1) }
  end

  def mark_as_started_download
    safe_operation(KSCourtKscourtsRuns) { @run_object.status = 'download started' }
  end

  def mark_as_finished_download
    safe_operation(KSCourtKscourtsRuns) { @run_object.status = 'download finished' }
  end

  def mark_as_started_store
    safe_operation(KSCourtKscourtsRuns) do |model|
      if @run_object.status == 'download finished'
        @run_object.status =  'store started'
       else
         raise "Scrape work is not finished correctly"
       end
    end
  end

  def finish
    safe_operation(KSCourtKscourtsRuns) { @run_object.finish }
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
