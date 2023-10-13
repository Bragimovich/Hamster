# frozen_string_literal: true

require_relative '../models/az_esa_reports_quarterly'
require_relative '../models/az_esa_reports_quarterly_runs'

class Keeper
  def initialize
    @run_object = RunId.new(AzEsaReportsQuarterlyRuns)
    @run_id = @run_object.run_id
  end

  def insert_record(hash_data)
    max_retries = 3
    retry_count = 0

    begin
      record = AzEsaReportsQuarterly.find_by(hash_data)

      if record.nil?
        hash_data.merge!(run_id: @run_id, touched_run_id: @run_id)
        AzEsaReportsQuarterly.create(hash_data)
      else
        record.update!(touched_run_id: @run_id, deleted: false)
      end
    rescue Mysql2::Error::ConnectionError => e
      retry_count += 1

      raise e if retry_count > max_retries

      try_reconnect
      retry
    end
  end

  def saved_pdf_urls
    AzEsaReportsQuarterly.select(:data_source_url).group(:data_source_url).map(&:data_source_url)
  end

  def finish
    @run_object.finish
  end

  def update_history
    deleted_records = AzEsaReportsQuarterly.where.not(touched_run_id: @run_id)
    deleted_records.update_all(deleted: true)
  end

  def members_count
    AzEsaReportsQuarterly.count
  end

  private

  def try_reconnect
    sleep_times = [0.1, 0.5, 1, 2, 4, 8]

    begin
      AzEsaReportsQuarterly.connection.reconnect!
    rescue Mysql2::Error => e
      sleep_time = sleep_times.shift
      if sleep_time
        sleep sleep_time
        retry
      else
        raise
      end
    end
  end
end
