# frozen_string_literal: true

class OrOregonInmateAdditionalInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'or_oregon_inmate_additional_info'
  self.inheritance_column = :_type_disabled
end
 