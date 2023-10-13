# frozen_string_literal: true
class IlCookBonds < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])

  self.table_name = 'il_cook__bonds'
  self.inheritance_column = :_type_disabled
end
