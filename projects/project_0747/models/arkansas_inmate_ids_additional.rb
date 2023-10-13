# frozen_string_literal: true

class ArkansasInmateIdsAdditional < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  include Hamster::Granary

  self.table_name = 'arkansas_inmate_ids_additional'
end
