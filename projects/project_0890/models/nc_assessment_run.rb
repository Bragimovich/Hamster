# frozen_string_literal: true

require_relative 'nc_assessmentable'
class NcAssessmentRun < ActiveRecord::Base
  include NcAssessmentable
end
