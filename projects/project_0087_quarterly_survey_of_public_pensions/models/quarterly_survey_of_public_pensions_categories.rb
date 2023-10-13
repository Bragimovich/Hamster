# frozen_string_literal: true

class QuarterlySurveyOfPublicPersonsCategory < ActiveRecord::Base
  establish_connection(Storage[host: :db13, db: :usa_raw])
  include Hamster::Granary
  self.table_name = 'quarterly_survey_of_public_pensions_categories'
end


