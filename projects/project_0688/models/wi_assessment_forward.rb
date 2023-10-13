require_relative 'wi_report_cardable'
class WiAssessmentForward < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'wi_assessment_forward'
end
