# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @run_id = @keeper.run_id
  end
  
  def store
    #store_general_info
    #@keeper.update_delete_status(AlGeneralInfo, AlAdministrators)
    store_college_career_readiness
    #@keeper.update_delete_status(AlCollegeCareerReadinesss)
    store_accountability_indicators
    #@keeper.update_delete_status(AlAccountabilityIndicators)
    store_enrollemt_data
    #@keeper.update_delete_status(AlEnrollment)
    store_schools_assessment
    #@keeper.update_delete_status(AlSchoolsAssessment, AlSchoolsAssessmentByLevels)
    update_numbers_column
    #@keeper.finish
    puts '____STORE DONE____'.green
  end

  def store_general_info
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Start store general_info"
    general_path = "#{storehouse}store/general_information"
    general_files = peon.list(subfolder: "general_information")

    superintendent_file = general_files.find { |file_name| file_name.match?(/^SystemContactInformation/) }
    @parser = Parser.new("#{general_path}/#{superintendent_file}", 2)
    @parser.district_data {|hash, model| @keeper.store_data(hash, model)}
    
    public_file = general_files.find { |file_name| file_name.match?(/^SchoolInformation.Public/) }
    @parser.read_csv("#{general_path}/#{public_file}", 2)
    @parser.public_data {|general_hash, admins_data| @keeper.store_public_or_private_data(general_hash, admins_data)}

    private_file = general_files.find { |file_name| file_name.match?(/^SchoolInformation_Private/) }
    @parser.read_csv("#{general_path}/#{private_file}", 2)   
    @parser.private_data {|general_hash, admins_data| @keeper.store_public_or_private_data(general_hash, admins_data)}
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Finish store general_info"
  end

  def store_enrollemt_data
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Start store enrollemt_data"
    general_path = "#{storehouse}store/enrollment"
    enrollment_files = peon.list(subfolder: "enrollment").select { |file| file.match?(/^SupportingData_StudentDemographics/) }.sort
    enrollment_files.each do |file_name|
      @parser = Parser.new("#{general_path}/#{file_name}")
      @parser.enrollment_data { |data_hash| @keeper.store_data(data_hash, AlEnrollment, relation: :general_id) }
    end
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Finish store enrollemt_data"
  end

  def store_college_career_readiness
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Start store college_career_readiness"
    general_path = "#{storehouse}store/college_career_readiness"
    career_files = peon.list(subfolder: "college_career_readiness").select { |file| file.match?(/^SupportingData_CCRGradRate/) }.sort
    career_files.each do |file_name|
      @parser = Parser.new("#{general_path}/#{file_name}")
      @parser.career_data { |data_hash| @keeper.store_data(data_hash, AlCollegeCareerReadinesss, relation: :general_id) }
    end
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Finish store college_career_readiness"
  end

  def store_accountability_indicators
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Start store accountability_indicators"
    general_path = "#{storehouse}store/accountability_indicators"
    career_files = peon.list(subfolder: "accountability_indicators").select { |file| file.match?(/^SupportingData_Accountability/) }.sort
    career_files.each do |file_name|
      @parser = Parser.new("#{general_path}/#{file_name}")
      @parser.accountability_data { |data_hash| @keeper.store_data(data_hash, AlAccountabilityIndicators, relation: :general_id) }
    end
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Finish store accountability_indicators"
  end

  def store_schools_assessment
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Start store schools_assessment"
    general_path = "#{storehouse}store/assessment"
    career_files = peon.list(subfolder: "assessment").select { |file| file.match?(/^SupportingData_Proficiency/) }.sort
    career_files.each do |file_name|
      @parser = Parser.new("#{general_path}/#{file_name}")
      @parser.assessment_data { |main_hash, level_hashes| @keeper.store_assessment_data(main_hash, level_hashes) }
    end
    # Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Finish store schools_assessment"
  end

  def update_numbers_column
    general_path = "#{storehouse}store/update_numbers"
    files = peon.list(subfolder: "update_numbers").reject { |file| file =~ /Identifier$/}
    files.each do |file_name|
      @parser = Parser.new("#{general_path}/#{file_name}")
      @parser.hash_for_update_numbers { |hash| @keeper.update_numbers_columns(hash) }
    end
  end
end
