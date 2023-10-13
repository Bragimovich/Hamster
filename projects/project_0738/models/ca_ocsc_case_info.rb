# frozen_string_literal: true

require_relative 'ca_ocsc_caseable'
class CaOcscCaseInfo < ActiveRecord::Base
  include CaOcscCaseable

  self.table_name = 'ca_ocsc_case_info'
end
