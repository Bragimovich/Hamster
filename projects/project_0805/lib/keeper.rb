# frozen_string_literal: true

require_relative '../models/hr_um_annual_salary_rate'
require_relative '../models/hr_um_annual_salary_rate_runs'

class Keeper < Hamster::Keeper

  def initialize
    @run_object = safe_operation(HrUmAnnualSalaryRateRun) { |model| RunId.new(model) }
    @run_id = safe_operation(HrUmAnnualSalaryRateRun) { @run_object.run_id }
  end

  attr_reader :run_id

  def flush(data_array)
    return if data_array.count.zero?

    sliced_arrays = data_array.each_slice(1000).to_a

    sliced_arrays.each do |array|
      db_run_ids =
      Hash[
        HrUmAnnualSalaryRate.where(
          md5_hash: array.map { |h| h[:md5_hash] }
        )
        .map { |r| [r.md5_hash, r.run_id] }
      ]
      array.each do |hash|
        hash[:run_id] = db_run_ids[hash[:md5_hash]] || @run_id
        hash[:updated_at] = Time.now
      end
      HrUmAnnualSalaryRate.upsert_all(array)
    end
  end

  def finish
    safe_operation(HrUmAnnualSalaryRateRun) { @run_object.finish }
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
