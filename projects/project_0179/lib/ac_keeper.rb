# frozen_string_literal: true

require_relative '../models/md_ac_case_runs'
require_relative '../models/md_ac_case_activity'
require_relative '../models/md_ac_case_additional_info'
require_relative '../models/md_ac_case_info'
require_relative '../models/md_ac_case_party'
class AcKeeper
  def initialize
    @run_object = RunId.new(MdAcCaseRuns)
    @run_id = @run_object.run_id
  end

  def finish
    @run_object.finish
  end

  def add_records(hash_data)
    max_retries = 3
    retry_count = 0

    begin
      MdAcCaseInfo.c__and__u!(@run_id, hash_data[:case_info])
      MdAcCaseParty.c__and__u!(@run_id, hash_data[:party_infos])
      MdAcCaseActivity.c__and__u!(@run_id, hash_data[:doc_infos])
      MdAcCaseAdditionalInfo.c__and__u!(@run_id, hash_data[:additional_infos])
    rescue Mysql2::Error::ConnectionError => e
      retry_count += 1

      raise e if retry_count > max_retries

      try_reconnect
      retry
    end
  end

  def update_history
    MdAcCaseInfo.update_history!(@run_id)
    MdAcCaseParty.update_history!(@run_id)
    MdAcCaseActivity.update_history!(@run_id)
    MdAcCaseAdditionalInfo.update_history!(@run_id)
  end

  private

  def try_reconnect
    sleep_times = [0.1, 0.5, 1, 2, 4, 8]

    begin
      MdAcCaseInfo.connection.reconnect!
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
