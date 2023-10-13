# frozen_string_literal: true

class ArkansasInmateAliases < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  include Hamster::Granary

  self.table_name = 'arkansas_inmate_aliases'
end
