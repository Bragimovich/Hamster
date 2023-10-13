# frozen_string_literal: true

class CaRiversideInmateAdditionalInfo < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'ca_riverside_inmate_additional_info'
    self.inheritance_column = :_type_disabled
end
