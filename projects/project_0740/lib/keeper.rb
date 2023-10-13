# frozen_string_literal: true
require_relative '../models/il_cccc_case_activities'
require_relative '../models/il_cccc_case_info'
require_relative '../models/il_cccc_case_party'
require_relative '../models/il_cccc_case_runs'


class Keeper
  def initialize
    @run_object = RunId.new(IlCcccCaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def get_cases()
    IlCcccCaseInfo.pluck(:case_id)
  end

  def insert_case_info(data_hash)
    retry_limit = 3
    retry_count = 0

    begin
      IlCcccCaseInfo.insert(data_hash)
    rescue StandardError => e
      Hamster.logger.debug "Error occurred: #{e.message}"
      if retry_count < retry_limit
        retry_count += 1
        Hamster.logger.debug "Retrying query (attempt #{retry_count})..."
        retry
      else
        Hamster.logger.debug "Retry limit reached. Unable to complete the query."
      end
    end
  end

  def insert_case_activities(data_array)
    retry_limit = 3
    retry_count = 0

    begin
      IlCcccCaseActivities.insert_all(data_array)
    rescue StandardError => e
      Hamster.logger.debug "Error occurred: #{e.message}"
      if retry_count < retry_limit
        retry_count += 1
        Hamster.logger.debug "Retrying query (attempt #{retry_count})..."
        retry
      else
        Hamster.logger.debug "Retry limit reached. Unable to complete the query."
      end
    end
  end

  def insert_case_party(data_array)
    retry_limit = 3
    retry_count = 0

    begin
      IlCcccCaseParty.insert_all(data_array)
    rescue StandardError => e
      Hamster.logger.debug "Error occurred: #{e.message}"
      if retry_count < retry_limit
        retry_count += 1
        Hamster.logger.debug "Retrying query (attempt #{retry_count})..."
        retry
      else
        Hamster.logger.debug "Retry limit reached. Unable to complete the query."
      end
    end
  end

  def finish
    @run_object.finish
  end
end
