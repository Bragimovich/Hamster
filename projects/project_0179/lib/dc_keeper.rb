# frozen_string_literal: true

require_relative '../models/md_dc_case_runs'
require_relative '../models/md_dc_case_activity'
require_relative '../models/md_dc_case_judgment'
require_relative '../models/md_dc_case_info'
require_relative '../models/md_dc_case_party'
class DcKeeper
  def initialize
    @run_object = RunId.new(MdDcCaseRuns)
    @run_id = @run_object.run_id
  end

  def finish
    @run_object.finish
  end

  def add_records(hash_data)
    max_retries = 3
    retry_count = 0

    begin
      MdDcCaseInfo.c__and__u!(@run_id, hash_data[:case_info])
      MdDcCaseParty.c__and__u!(@run_id, hash_data[:party_infos])
      MdDcCaseActivity.c__and__u!(@run_id, hash_data[:doc_infos])
      MdDcCaseJudgment.c__and__u!(@run_id, hash_data[:judgment_info])
    rescue Mysql2::Error::ConnectionError => e
      retry_count += 1

      raise e if retry_count > max_retries

      try_reconnect
      retry
    end
  end

  def update_history
    MdDcCaseInfo.update_history!(@run_id)
    MdDcCaseParty.update_history!(@run_id)
    MdDcCaseActivity.update_history!(@run_id)
    MdDcCaseJudgment.update_history!(@run_id)
  end

  private

  def try_reconnect
    sleep_times = [0.1, 0.5, 1, 2, 4, 8]

    begin
      MdDcCaseInfo.connection.reconnect!
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
