# frozen_string_literal: true

class IlLaSalleCharges < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
  include Hamster::Granary

  self.table_name = 'il_la_salle_charges'
  self.logger = Logger.new(STDOUT)
end
