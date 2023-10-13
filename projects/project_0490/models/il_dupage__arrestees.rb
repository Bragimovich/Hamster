# frozen_string_literal: true

class IlDuPageArrestee < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
  include Hamster::Granary
  
  self.table_name = 'il_dupage__arrestees'
  self.logger = Logger.new(STDOUT)
end
