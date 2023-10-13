# frozen_string_literal: true

require_relative '../models/la_3c_ac_case_activity'
require_relative '../models/la_3c_ac_case_additional_info'
require_relative '../models/la_3c_ac_case_info'
require_relative '../models/la_3c_ac_case_party'
require_relative '../models/la_3c_ac_case_pdfs_on_aws'
require_relative '../models/la_3c_ac_case_relations_activity_pdf'
require_relative '../models/la_3c_ac_case_runs'

class Keeper
  include Hamster::Loggable

  def initialize
    @run_object = RunId.new(La3cAcCaseRuns)
    @run_id = @run_object.run_id
  end

  def add_records(opinions)
    retry_connect_count = 0
    case_id = nil
    begin
      opinions.each do |opinion|
        case_id = opinion[:case_info][:case_id]
        La3cAcCaseInfo.c__and__u!(@run_id, opinion[:case_info])
        La3cAcCaseAdditionalInfo.c__and__u!(@run_id, opinion[:case_additional_info])
        La3cAcCaseActivity.c__and__u!(@run_id, opinion[:case_activities])
        La3cAcCasePdfsOnAws.c__and__u!(@run_id, opinion[:case_pdfs_on_aws])
        La3cAcCaseRelationsActivityPdf.c__and__u!(@run_id, opinion[:case_activity_pdf])
        opinion[:case_party].each do |hash_data|
          La3cAcCaseParty.create_and_update!(@run_id, hash_data)
        end
        logger.debug "Touched case info: #{case_id}"
      end
    rescue StandardError => e
      retry_connect_count += 1

      raise e if retry_connect_count > 30

      sleep_times = retry_connect_count * retry_connect_count * 10
      logger.info "Raised error(#{retry_connect_count}) when adding the record #{case_id}, sleeping #{sleep_times} seconds"
      
      sleep sleep_times
      try_reconnect

      retry
    end
  end

  def finish
    @run_object.finish
  end

  def update_history
    La3cAcCaseInfo.update_history!(@run_id)
    La3cAcCaseAdditionalInfo.update_history!(@run_id)
    La3cAcCaseActivity.update_history!(@run_id)
    La3cAcCasePdfsOnAws.update_history!(@run_id)
    La3cAcCaseRelationsActivityPdf.update_history!(@run_id)
    La3cAcCaseParty.update_history!(@run_id)
  end

  private

  def try_reconnect
    sleep_times = [2, 4, 8]

    begin
      La3cAcCaseInfo.connection.reconnect!
    rescue StandardError => e
      sleep_time = sleep_times.shift
      if sleep_time
        sleep sleep_time

        retry
      end
    end
  end
end
