# frozen_string_literal: true

class  IlWillMugshots < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
  include Hamster::Granary
  self.inheritance_column = :_type_disabled

  self.table_name = 'il_will__mugshots'
end
