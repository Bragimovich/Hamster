# frozen_string_literal: true
require_relative 'wi_report_cardable'
class UsDistricts < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'us_districts'
end

class UsSchools < ActiveRecord::Base
  include WiReportCardable

  self.table_name = 'us_schools'
end
