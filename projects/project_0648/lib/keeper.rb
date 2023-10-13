# frozen_string_literal: true

require_relative '../models/fl_occc_case_runs'
require_relative '../models/fl_occc_case_info'
require_relative '../models/fl_occc_case_party'
require_relative '../models/fl_occc_case_activities'
require_relative '../models/fl_occc_case_pdfs_on_aws'
require_relative '../models/fl_occc_case_relations_activity_pdf'
require_relative '../models/fl_occc_case_scrape_date_track'
require_relative '../models/fl_occc_case_scrape_date_track_cron'

class Keeper < Hamster::Keeper
  DB_MODELS = { 'info' => FlOcccCaseInfo, 'party' => FlOcccCaseParty, 'activity' => FlOcccCaseActivities, 'activity_pdf_relation' => FlOcccCaseRelationsActivityPdf, 'aws_pdf' => FlOcccCasePdfsOnAws }

  def initialize
    @run_object = safe_operation(FlOcccCaseRun) { |model| RunId.new(model) }
    @run_id = safe_operation(FlOcccCaseRun) { @run_object.run_id }
  end

  attr_reader :run_id

  def insert_data(data_hash)
    data_hash.each do |key, value|
      safe_operation(DB_MODELS[key]) { |model| model.insert_all(value) } unless value.empty?
    end
  end

  def get_processed_dates
    ScrapeDateTrackCron.where(is_completed: true).pluck(:searched_date) #from here 2023-02-22 this is manual insertion
  end

  def insert_scrape_date_track(data_hash)
    safe_operation(ScrapeDateTrack) { |model| model.insert(data_hash) }
  end

  def insert_scrape_date_track_cron(data_hash)
    safe_operation(ScrapeDateTrackCron) { |model| model.insert(data_hash) }
  end

  def already_processed_dates
    year_array = safe_operation(ScrapeDateTrack) { |model| model.where(month: 0, is_completed: true).or(model.where(month: 0, need_to_split: true)).or(model.where(month: 0, processing_error: true)).or(model.where(month: 0, bad_request: true)).or(model.where(month: 0, no_links: true)).pluck(:year, :case_type) }

    year_month_array = safe_operation(ScrapeDateTrack) { |model| model.where(day: 0, is_completed: true).or(model.where(day: 0, need_to_split: true)).or(model.where(day: 0, processing_error: true)).or(model.where(day: 0, bad_request: true)).or(model.where(day: 0, no_links: true)).pluck(:year, :month, :case_type) }

    year_month_day_array = safe_operation(ScrapeDateTrack) { |model| model.where(letter: '-', is_completed: true).or(model.where(letter: '-', need_to_split: true)).or(model.where(letter: '-', processing_error: true)).or(model.where(letter: '-', bad_request: true)).or(model.where(letter: '-', no_links: true)).pluck(:year, :month, :day, :case_type) }

    year_month_day_letter_array = safe_operation(ScrapeDateTrack) { |model| model.where(is_completed: true).or(model.where(need_to_split: true)).or(model.where(processing_error: true)).or(model.where(bad_request: true)).or(model.where(no_links: true)).pluck(:year, :month, :day, :letter, :case_type) }

    [year_array, year_month_array, year_month_day_array, year_month_day_letter_array]
  end

  def info_case_ids
    safe_operation(FlOcccCaseInfo) { |model| model.pluck(:case_id) }
  end

  def finish
    safe_operation(FlOcccCaseRun) { @run_object.finish }
  end
  
  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        # logger.error "#{e.class}"
        # logger.error "Reconnect!"
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
