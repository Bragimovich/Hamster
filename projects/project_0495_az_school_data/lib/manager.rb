# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../models/az_assessment'
require_relative '../models/az_enrollment'
require_relative '../models/az_dropout'
require_relative '../models/az_cohort'
require_relative '../lib/keeper'

require 'roo'
require 'pry'

class Manager < Hamster::Harvester

  URL = 'https://www.azed.gov/accountability-research/data/'
  BASE_URL = 'https://www.azed.gov'
  WILLIAM_DEVRIES = 'U04JLLPDLPP'
  def initialize
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download_enrollment_files(year)
    if AzEnrollment.count > 100
      Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Enrollment data for (#{year}) has been loaded already!.")
      return
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Started downloading enrollment files(#{year})!")
    response = @scraper.get_response(URL)
    links = @parser.get_enrollment_links(response.body)
    links.each do |xlsx_link|
      next unless xlsx_link[:text].include?("-#{year.to_s}")

      file_name = @parser.get_xlsx_filename_underscored(xlsx_link[:text])      
      full_url = @parser.get_full_xlsx_url(xlsx_link[:href])
      @scraper.download_xlsx_file(full_url, file_name, 'enrollment/')
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Finished downloading enrollment files(#{year})!")
  end

  def download_assessment_files(year)
    if AzAssessment.count > 100
      Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Assessment data for (#{year}) has been loaded already!")
      return
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Started downloading assessment files(#{year})!")
    response = @scraper.get_response(URL)
    links = @parser.get_assessment_links(response.body)
    
    links.each do |xlsx_link|
      next unless xlsx_link[:text].include?("#{year.to_s}")
      file_name = @parser.get_xlsx_filename_underscored(xlsx_link[:text])
      full_url = @parser.get_full_xlsx_url(xlsx_link[:href])
      @scraper.download_xlsx_file(full_url, file_name, 'assessment/')
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Finished downloading assessment files(#{year})!")
  end

  def download_dropout_files(year)
    if AzDropout.count > 100
      Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Dropout data for (#{year}) has been loaded already!")
      return
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Started downloading dropout files(#{year})!")
    response = @scraper.get_response(URL)
    links = @parser.get_dropout_links(response.body)
    
    links.each do |xlsx_link|
      next unless xlsx_link[:text].include?("#{year.to_s}")
      file_name = @parser.get_xlsx_filename_underscored(xlsx_link[:text])
      full_url = @parser.get_full_xlsx_url(xlsx_link[:href])
      @scraper.download_xlsx_file(full_url, file_name, 'dropout/')
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Finished downloading dropout files(#{year})!")
  end

  def download_cohort_files(year)
    if AzCohort.count > 100
      Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Cohort data for (#{year}) has been loaded already!")
      return
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Started downloading cohort files(#{year})!")
    response = @scraper.get_response(URL)
    links = @parser.get_cohort_links(response.body)
    links.each do |xlsx_link|
      next unless xlsx_link[:text].include?("#{year.to_s}")
      file_name = @parser.get_xlsx_filename_underscored(xlsx_link[:text])
      full_url = @parser.get_full_xlsx_url(xlsx_link[:href])
      @scraper.download_xlsx_file(full_url, file_name, 'cohort/')
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Finished downloading cohort files(#{year})!")
  end
  
  def clear_assessment_files
    @scraper.clear_assessment_files
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Cleared assessment files!")
  end

  def clear_enrollment_files
    @scraper.clear_enrollment_files
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Cleared enrollment files!")
  end

  def clear_dropout_files
    @scraper.clear_dropout_files
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Cleared dropout files!")
  end

  def clear_cohort_files
    @scraper.clear_cohort_files
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Cleared cohort files!")
  end

  def store_assessment(year)
    if AzAssessment.count > 100
      Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Assessment data for (#{year}) has been loaded already!.")
      return
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Started storing assessment data for #{year}.")
    assessment_xlsx_files = @scraper.get_assessment_xlsx_files
    
    assessment_xlsx_files.each do |xlsx_file|
      next unless xlsx_file.include?(year.to_s)
      roo_xlsx = Roo::Excelx.new(xlsx_file)
      @keeper.store_az_assessment_from_xlsx(roo_xlsx, year)
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Finished storing assessment data for #{year}.")
  end

  def store_enrollment(year)
    if AzEnrollment.count > 100
      Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Enrollment data for (#{year}) has been loaded already!.")
      return
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Started storing enrollment data for #{year}.")
    enrollment_xlsx_files = @scraper.get_enrollment_xlsx_files

    enrollment_xlsx_files.each do |xlsx_file|
      next unless xlsx_file.include?("_#{year.to_s}")
      roo_xlsx = Roo::Excelx.new(xlsx_file)
      @keeper.store_az_enrollment_from_xlsx(roo_xlsx, year)
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Finished storing enrollment data for #{year}.")
  end

  def store_dropout(year)
    if AzDropout.count > 100
      Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Dropout data for (#{year}) has been loaded already!.")
      return
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Started storing dropout data for #{year}.")
    dropout_xlsx_files = @scraper.get_dropout_xlsx_files
    
    dropout_xlsx_files.each do |xlsx_file|
      next unless xlsx_file.include?("_#{year.to_s}")
      roo_xlsx = Roo::Excelx.new(xlsx_file)
      @keeper.store_az_dropout_from_xlsx(roo_xlsx, year)
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Finished storing dropout data for #{year}.")
  end

  
  def store_store_cohort(year)
    if AzCohort.count > 100
      Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Cohort data for (#{year}) has been loaded already!.")
      return
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Started storing cohort data for #{year}.")
    cohort_xlsx_files = @scraper.get_cohort_xlsx_files
    
    cohort_xlsx_files.each do |xlsx_file|
      next unless xlsx_file.include?("#{year.to_s}")
      roo_xlsx = Roo::Excelx.new(xlsx_file)
      @keeper.store_az_cohort_from_xlsx(roo_xlsx, year)
    end
    Hamster.report(to: WILLIAM_DEVRIES, message: "Task #0495 - Finished storing cohort data for #{year}.")
  end

  def correct_md5_hash
    # @keeper.correct_md5_hash_for_az_cohort # Done
    # @keeper.correct_md5_hash_for_az_dropout
    # @keeper.correct_md5_hash_for_az_enrollment
    @keeper.correct_md5_hash_for_az_assessment
  end


end
