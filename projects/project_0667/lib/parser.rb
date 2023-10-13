require 'roo'
require_relative '../lib/la_enrollment'
require_relative '../lib/la_assessment_leap'
require_relative '../lib/la_assessment_leap_subgroup'
require_relative '../lib/la_assessment_kg_entry'
require_relative '../lib/la_discipline_rate'
require_relative '../lib/la_discipline_ethnicity_grade'
require_relative '../lib/la_discipline_reason'

class Parser < Hamster::Parser

  include LaAssessmentKgEntry
  include LaAssessmentLeap
  include LaAssessmentLeapSubgroup
  include LaDisciplineEthnicityGrade
  include LaDisciplineRate
  include LaDisciplineReason
  include LaEnrollment

  def initialize
    super
    @keeper = Keeper.new
  end

  def find_folder_and_links(html, search_text, type)
    links_array = []
    doc = Nokogiri::HTML.parse(html)
    all_files = doc.css('#body_copy div.sf_colsOut')[1..]
    all_files.each do |file|
      hash = {}
      period = file.css('h2').text
      links = file.css('tr').select { |tr| tr.text.include? search_text } unless type == 'assessment'
      links = file.css('tr').select { |tr| tr.text.include? search_text[0] or tr.text.include? search_text[1] } if type == 'assessment'
      links =  links.map { |e| e.css('a')[0]['href']}
      hash[:period] = period
      hash[:links] = links
      links_array << hash   
    end
    links_array
  end

  def find_links(html, search_text)
    doc = Nokogiri::HTML.parse(html)
    all_files = doc.css('#body_copy tbody tr').select { |tr| tr.text.include? search_text }
    all_files.map { |e| e.css('a')[0]['href']}
  end
end
