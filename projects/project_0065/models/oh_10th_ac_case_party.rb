# frozen_string_literal: true

class Oh10thAcCaseParty < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary

  self.table_name = 'oh_10th_ac_case_party'
  self.logger = Logger.new(STDOUT)
end
