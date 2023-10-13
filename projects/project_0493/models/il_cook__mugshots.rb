# frozen_string_literal: true
class IlCookMugshots < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])

  self.table_name = 'il_cook__mugshots'
  self.inheritance_column = :_type_disabled
end
