# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  attr_accessor :parser, :keeper, :scraper

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def store_general_info
    keeper.store_general_info
  end

  def store_enrollment
    general_id = keeper.get_general_id
    offset = 0
    loop do
      enrollment_url = "https://data.delaware.gov/resource/6i7v-xnmf.json?$limit=10000&$offset=#{offset}"
      enrollment_response = scraper.get_json(enrollment_url)
      enrollment_data = parser.parse_json_enrollment(enrollment_response, general_id)
      break if enrollment_data.empty?
      keeper.store_data(enrollment_data, DeEnrollment)
      offset += 10000
    end
  end

  def store_graduation
    general_id = keeper.get_general_id
    offset = 0
    loop do
      graduation_url = "https://data.delaware.gov/resource/t7e6-zcnn.json?$limit=10000&$offset=#{offset}"
      graduation_response = scraper.get_json(graduation_url)
      graduation_data = parser.parse_json_graduation(graduation_response, general_id)
      break if graduation_data.empty?
      keeper.store_data(graduation_data, DeGraduation)
      offset += 10000
    end
  end

  def store_growth
    general_id = keeper.get_general_id
    offset = 0
    loop do
      growth_url = "https://data.delaware.gov/resource/kqmb-6xbs.json?$limit=10000&$offset=#{offset}"
      growth_response = scraper.get_json(growth_url)
      growth_data = parser.parse_json_growth(growth_response, general_id)
      break if growth_data.empty?
      keeper.store_data(growth_data, DeGrowth)
      offset += 10000
    end
  end

  def store_salary
    general_id = keeper.get_general_id
    offset = 0
    loop do
      salary_url = "https://data.delaware.gov/resource/rv4m-vy79.json?$limit=10000&$offset=#{offset}"
      salary_response = scraper.get_json(salary_url)
      salary_data = parser.parse_json_salary(salary_response, general_id)
      break if salary_data.empty?
      keeper.store_data(salary_data, DeSalary)
      offset += 10000
    end
  end

  def store_assessment
    general_id = keeper.get_general_id
    offset = 0
    loop do
      assessment_url = "https://data.delaware.gov/resource/ms6b-mt82.json?$limit=10000&$offset=#{offset}"
      assessment_response = scraper.get_json(assessment_url)
      assessment_data = parser.parse_json_assessment(assessment_response, general_id)
      break if assessment_data.empty?
      keeper.store_data(assessment_data, DeAssessment)
      offset += 10000
    end
  end

  def store_discipline
    general_id = keeper.get_general_id
    offset = 0
    loop do
      discipline_url = "https://data.delaware.gov/resource/yr4w-jdi4.json?$limit=10000&$offset=#{offset}"
      discipline_response = scraper.get_json(discipline_url)
      discipline_data = parser.parse_json_discipline(discipline_response, general_id)
      break if discipline_data.empty?
      keeper.store_data(discipline_data, DeDiscipline)
      offset += 10000
    end
    keeper.finish
  end
end
