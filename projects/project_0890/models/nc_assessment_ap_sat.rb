# frozen_string_literal: true

require_relative 'nc_assessmentable'
class NcAssessmentApSat < ActiveRecord::Base
  include NcAssessmentable
  self.table_name = 'nc_assessment_ap_sat'
end
