# frozen_string_literal: true
class InMarionInmateAdditionalInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'in_marion_inmate_additional_info'
  self.inheritance_column = :_type_disabled
end
