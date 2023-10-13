# frozen_string_literal: true

class RawKyJacksonCountyInmatesArrests < ActiveRecord::Base
  
  establish_connection(Storage[host: :db01, db: :foia_inmate_gather])
  self.table_name = 'raw_ky_jackson_county_inmates_arrests_from_1_1_2019_to_2_4_2023'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
