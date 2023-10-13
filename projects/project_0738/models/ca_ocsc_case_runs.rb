# frozen_string_literal: true

class CaOcscCaseRuns < ActiveRecord::Base
  include Hamster::Loggable

  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'ca_ocsc_case_runs'
  self.inheritance_column = :_type_disabled
end
