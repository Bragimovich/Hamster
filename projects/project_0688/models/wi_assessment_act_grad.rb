require_relative 'wi_report_cardable'
class WiAssessmentActGrad < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'wi_assessment_act_grad'
end
