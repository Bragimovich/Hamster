# frozen_string_literal: true

require_relative 'ca_ocsc_caseable'
class CaOcscCaseParty < ActiveRecord::Base
  include CaOcscCaseable

  self.table_name = 'ca_ocsc_case_party'
end
