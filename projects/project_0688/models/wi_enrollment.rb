require_relative 'wi_report_cardable'
class WiEnrollment < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'wi_enrollment'
end
