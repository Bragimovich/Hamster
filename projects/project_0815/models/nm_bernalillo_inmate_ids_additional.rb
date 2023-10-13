# frozen_string_literal: true
class NmBernalilloInmateIdsAdditional < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'nm_bernalillo_inmate_ids_additional'
  self.inheritance_column = :_type_disabled
end
