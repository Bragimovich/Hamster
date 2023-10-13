# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  
  year = options[:year]
  if year.nil?
    year = Date.today.year
  end
  
  Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - started running.")

  manager = Manager.new

  if options[:auto]
    Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - started downloading.")
    manager.download_assessment_files(year)
    manager.download_enrollment_files(year)
    manager.download_dropout_files(year)
    manager.download_cohort_files(year)
    Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - finished downloading.")

    Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - started storing.")
    manager.store_assessment(year)
    manager.store_enrollment(year)
    manager.store_dropout(year)
    manager.store_store_cohort(year)
    Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - finished storing.")

    manager.clear_assessment_files
    manager.clear_enrollment_files
    manager.clear_dropout_files
    manager.clear_cohort_files
  elsif options[:download]
    Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - started downloading.")
    manager.download_assessment_files(year)
    manager.download_enrollment_files(year)
    manager.download_dropout_files(year)
    manager.download_cohort_files(year)
    Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - finished downloading.")
  elsif options[:store]
    Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - started storing.")
    manager.store_assessment(year)
    manager.store_enrollment(year)
    manager.store_dropout(year)
    manager.store_store_cohort(year)
    Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - finished storing.")
    manager.clear_assessment_files
    manager.clear_enrollment_files
    manager.clear_dropout_files
    manager.clear_cohort_files
  end

  Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "Task #0495 - finished running.")
  # manager.correct_md5_hash
rescue StandardError => e
  Hamster.logger.error "#{e}".red
  Hamster.logger.error e.backtrace
  Hamster.logger.error "####################################".red
  Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "##{Hamster.project_number} | #{e}", use: :both)
end
