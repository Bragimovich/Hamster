# frozen_string_literal: true

require_relative '../models/NC_RAW_Candidate_Listing'
require_relative '../models/NC_RAW_Candidate_run'
require_relative '../models/NC_RAW_Candidates2018_extras'
require_relative '../models/NC_RAW_Candidates2020_extras'
require_relative '../models/NC_RAW_Candidates2021_emails'
require_relative '../models/NC_RAW_Expenditures'
require_relative '../models/NC_RAW_NCVOTER'
require_relative '../models/NC_RAW_Receipts'

class Keeper < Hamster::Keeper

  def initialize
    @run_object = safe_operation(NcRawCandidateRun) { |model| RunId.new(model) }
    @run_id = safe_operation(NcRawCandidateRun) { @run_object.run_id }
  end

  def insert_candidates_csv_data(data_array)
    NcRawCandidateListing.insert_all(data_array)
    logger.info "*************** Inseting Candidate CsV Data ***************"
  end

  def insert_expenditures_csv_data(data_array)
    NcRawExpenditures.insert_all(data_array)
    logger.info "*************** Inseting Expenditure CsV Data ***************"
  end

  def insert_receipts_csv_data(data_array)
    NcRawReceipts.insert_all(data_array)
    logger.info "*************** Inseting Receipt CsV Data ***************"
  end

  def insert_candidate_2018_xlsx_data(data_array)
    NcRawCandidates2018Extras.insert_all(data_array)
    logger.info "*************** Inseting 2018 XlSx Data ***************"
  end

  def insert_candidate_2020_xlsx_data(data_array)
    NcRawCandidates2020Extras.insert_all(data_array)
    logger.info "*************** Inseting 2020 XlSx Data ***************"
  end
  
  def insert_candidate_2021_xlsx_data(data_array)
    NcRawCandidates2021Emails.insert_all(data_array)
    logger.info "*************** Inseting 2021 XlSx Data ***************"
  end
  
  def insert_voter_txt_data(data_array)
    NcRawNcvoter.insert_all(data_array)
    logger.info "*************** Inseting TxT Data ***************"
  end

  attr_reader :run_id
   
  def finish
    safe_operation(NcRawCandidateRun) { @run_object.finish }
  end
  
  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.error "#{e.class}"
        logger.info '*'*77, "Reconnect!", '*'*77
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
