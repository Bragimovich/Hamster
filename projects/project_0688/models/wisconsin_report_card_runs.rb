require_relative 'wi_report_cardable'
class WisconsinReportCardRuns < ActiveRecord::Base
  include WiReportCardable
  
  self.table_name = 'wisconsin_report_card_runs'
end
