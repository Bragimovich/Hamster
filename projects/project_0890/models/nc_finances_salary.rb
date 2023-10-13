# frozen_string_literal: true

require_relative 'nc_assessmentable'
class NcFinancesSalary < ActiveRecord::Base
  include NcAssessmentable
end
