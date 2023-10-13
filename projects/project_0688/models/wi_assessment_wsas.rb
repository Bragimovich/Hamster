require_relative 'wi_report_cardable'
class WiAssessmentWsas < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'wi_assessment_wsas'
end
