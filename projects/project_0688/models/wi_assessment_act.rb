require_relative 'wi_report_cardable'
class WiAssessmentAct < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'wi_assessment_act'
end
