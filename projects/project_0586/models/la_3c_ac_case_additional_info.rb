# frozen_string_literal: true

require_relative 'la_3c_ac_case_concern'
class La3cAcCaseAdditionalInfo < ActiveRecord::Base
  include La3cAcCaseConcern

  self.table_name = 'la_3c_ac_case_additional_info'
end
