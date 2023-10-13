# frozen_string_literal: true

require_relative 'nc_assessmentable'
class NcFinacesExpenditure < ActiveRecord::Base
  include NcAssessmentable
end
