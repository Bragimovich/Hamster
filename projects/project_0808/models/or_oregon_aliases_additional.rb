# frozen_string_literal: true

class OrOregonAliasesAdditional < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate]) 
  self.table_name = 'or_oregon_aliases_additional'
  self.inheritance_column = :_type_disabled
end
 