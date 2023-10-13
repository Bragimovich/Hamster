require_relative 'wi_report_cardable'
class WiAttendance < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'wi_attendance'
end
