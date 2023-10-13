# frozen_string_literal: true

require_relative '../models/ca_ocsc_case_info'
require_relative '../models/ca_ocsc_case_activity'
require_relative '../models/ca_ocsc_case_party'
require_relative '../models/ca_ocsc_case_runs'
class Keeper
  include Hamster::Loggable

  attr_reader :run_id
  def initialize
    @run_object = RunId.new(CaOcscCaseRuns)
    @run_id = @run_object.run_id
  end

  def insert_record(hash_data)
    case_id = hash_data[:case_info][:case_id]
    begin
      CaOcscCaseInfo.c__and__u!(@run_id, hash_data[:case_info])
      CaOcscCaseActivity.c__and__u!(@run_id, hash_data[:activity_info])
      CaOcscCaseParty.c__and__u!(@run_id, hash_data[:party_info])
      logger.info "touched record, case id is #{case_id} and run_id is #{@run_id}"
    rescue StandardError => e
      logger.info "Raised error when adding case: #{case_id}"
      logger.info e.full_message
    end
  end

  def finish
    @run_object.finish
  end

  def update_history
    CaOcscCaseInfo.update_history!(@run_id)
    CaOcscCaseActivity.update_history!(@run_id)
    CaOcscCaseParty.update_history!(@run_id)
  end
end
