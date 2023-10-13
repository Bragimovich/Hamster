# frozen_string_literal: true

require_relative 'ca_ocsc_caseable'
class CaOcscCaseActivity < ActiveRecord::Base
  include CaOcscCaseable

  self.table_name = 'ca_ocsc_case_activities'
end
