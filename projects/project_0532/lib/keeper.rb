# frozen_string_literal: true

require_relative '../models/hi_bar__hsba_org'
require_relative '../models/hi_bar__hsba_org_runs'

class Keeper
  include Hamster::Loggable
  attr_reader :run_id
  def initialize
    @run_object = RunId.new(HsbaLawyerRuns)
    @run_id = @run_object.run_id
  end

  def insert_record(hash_data)
    max_retries = 30
    retry_connect_count = 0

    begin
      record = HsbaLawyer.find_by(bar_number: hash_data[:bar_number])

      if record.nil?
        hash_data.merge!(run_id: @run_id, touched_run_id: @run_id)
        HsbaLawyer.create(hash_data)
      elsif record.md5_hash != hash_data[:md5_hash]
        hash_data.merge!(touched_run_id: @run_id, deleted: false)
        record.update!(hash_data)
      else
        record.update!(touched_run_id: @run_id, deleted: false)
      end
    rescue StandardError => e
      retry_connect_count += 1

      raise e if retry_connect_count > max_retries

      sleep_times = retry_connect_count * retry_connect_count * 10
      logger.info "Raised error(#{retry_connect_count}) when adding the record #{hash_data[:bar_number]}, sleeping #{sleep_times} seconds"
      logger.info e.full_message
      
      sleep sleep_times
      try_reconnect
      retry
    end
  end

  def finish
    @run_object.finish
  end

  def update_history
    deleted_records = HsbaLawyer.where.not(touched_run_id: @run_id)
    deleted_records.update_all(deleted: true)
  end

  def members_count
    HsbaLawyer.count
  end

  private

  def try_reconnect
    sleep_times = [2, 4, 8]

    begin
      HsbaLawyer.connection.reconnect!
    rescue StandardError => e
      sleep_time = sleep_times.shift
      if sleep_time
        sleep sleep_time

        retry
      end
    end
  end
end
