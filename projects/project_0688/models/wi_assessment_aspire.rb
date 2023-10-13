require_relative 'wi_report_cardable'
class WiAssessmentAspire < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'wi_assessment_aspire'
end
