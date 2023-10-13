# frozen_string_literal: true

require_relative 'nc_assessmentable'
class NcAssessmentAct < ActiveRecord::Base
  include NcAssessmentable
  self.table_name = 'nc_assessment_act'
end
