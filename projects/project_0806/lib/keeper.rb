# frozen_string_literal: true

require_relative "../models/wirepoints"
require_relative "../models/wirepoint_runs"

class Keeper < Hamster::Harvester

  MD5_ARRAYS =  [ @wirepoint_md5_array = [] ]
  TABLES_MODEL =  [ Wirepoint ]

  def initialize
    super
    @run_object = safe_operation(WirepointRun) { |model| RunId.new(model) }
    @run_id = safe_operation(WirepointRun) { @run_object.run_id }
  end

  def insert_all_data(data_hash)
    Wirepoint.insert(data_hash)
    MD5_ARRAYS.first.push(data_hash["md5_hash"])
    logger.info "Data Insertion Done"
  end
    
  def update_touch_run_id
    TABLES_MODEL.first.where(:md5_hash => MD5_ARRAYS.first).update_all(:touched_run_id => run_id)
  end

  def mark_deleted
    TABLES_MODEL.first.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end
  
  def finish
    safe_operation(WirepointRun) { @run_object.finish }
  end
  
  attr_reader :run_id, :models_hash
  private
  
  
  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise "Connection could not be established" if retries.zero?
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
