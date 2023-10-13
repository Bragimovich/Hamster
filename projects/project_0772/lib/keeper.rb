# frozen_string_literal: true
require_relative '../models/ar_higher_ed_salaries'
require_relative '../models/ar_higher_ed_salaries_runs'

class Keeper

  RUNID_MODELS    = %w[ArHigherEdSalaries]

  attr_reader :run_id
  def initialize
    @run_object = RunId.new(ArHigherEdSalariesRuns)
    @run_id = @run_object.run_id
  end

  def store_data(data, model, options)
    array_hashes = data.is_a?(Array) ? data : [data]
    safe_operation(model) do |model|
      array_hashes.each do |raw_hash|
        raw_hash = raw_hash.merge(options)
        raw_hash[:touched_run_id] = @run_id
        raw_hash[:run_id] = @run_id
        md5_hash = get_md5_hash(raw_hash)
        model.insert(raw_hash.merge(md5_hash: md5_hash))
      end
    end
  end

  def get_md5_hash(data_hash)
    data_hash_sliced = data_hash.slice(
      :fiscal_year,
      :campus,
      :payee,
      # :amount_paid,
      :position_title,
      :data_type,
      :touched_run_id
    )
    data_string = data_hash_sliced.values.inject('') { |str, val| str += val.to_s }
    md5_hash = Digest::MD5.hexdigest(data_string)
  end

  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        sleep 100
        Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "project-#{Hamster::project_number} Keeper: Reconnecting...")
        model.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end
    retry
    end
  end

  def re_generate_md5_hash
    ArHigherEdSalaries.where(md5_hash: nil).each do |rec|
      md5_hash = get_md5_hash(rec)
      rec.update(md5_hash: md5_hash)
    end
  end

  def reset_amount_paid
    ArHigherEdSalaries.where(amount_paid: '').each do |rec|
      rec[:amount_paid] = nil
      md5_hash = get_md5_hash(rec)
      rec.update(md5_hash: md5_hash, amount_paid: nil)
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

  def mark_deleted(year)
    RUNID_MODELS.each do |model_name|
      model_class  = model_name.constantize
      model_class.where.not(touched_run_id: @run_id).where(fiscal_year: year).update_all(deleted: true)
      model_class.where(touched_run_id: @run_id).update_all(deleted: false)
      Hamster.close_connection(model_class)
    end
  end

  def finish(year)
    mark_deleted(year)
    @run_object.finish
  end

end
