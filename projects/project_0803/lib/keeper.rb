# frozen_string_literal: true

require_relative '../models/cpi_inflations'
require_relative '../models/cpi_inflation_runs'

class Keeper < Hamster::Keeper
  MAX_BUFFER_SIZE = 110

  def initialize
    @run_object = safe_operation(CpiInflationRun) { |model| RunId.new(model) }
    @run_id = safe_operation(CpiInflationRun) { @run_object.run_id }
    @buffer = []
    @md5_array = []
  end

  attr_reader :run_id, :md5_array

  def insert_data(data_hash)
    @buffer << data_hash
    flush if @buffer.count >= MAX_BUFFER_SIZE
    md5_array.push(data_hash["md5_hash"])
    if md5_array.count >= MAX_BUFFER_SIZE
      update_touched_run_id
      md5_array.clear
    end
  end

  def flush
    return if @buffer.count.zero?

    db_run_ids =
    Hash[
      CpiInflation.where(
        md5_hash: @buffer.map { |h| h[:md5_hash] }
      )
      .map { |r| [r.md5_hash, r.run_id] }
    ]

    @buffer.each do |hash|
      hash[:run_id] = db_run_ids[hash[:md5_hash]] || @run_id
      hash[:updated_at] = Time.now
    end

    CpiInflation.upsert_all(@buffer)
    @buffer = []
  end
  
  def finish
    safe_operation(CpiInflationRun) { @run_object.finish }
  end
  
  def update_touched_run_id
    CpiInflation.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id)
  end

  def mark_deleted
    CpiInflation.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end
  
  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.error "#{e.class}"
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
