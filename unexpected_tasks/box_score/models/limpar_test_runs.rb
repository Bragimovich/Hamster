# frozen_string_literal: true

class LimparTestRun < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary

  self.table_name = 'limpar_test_runs'
  self.logger = Logger.new(STDOUT)
end