# frozen_string_literal: true
class CtHigherEducationSalariesRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'ct_higher_education_salaries_runs'
  self.logger     = Logger.new(STDOUT)
end
