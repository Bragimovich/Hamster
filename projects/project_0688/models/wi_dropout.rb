require_relative 'wi_report_cardable'
class WiDropout < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'wi_dropout'
end
