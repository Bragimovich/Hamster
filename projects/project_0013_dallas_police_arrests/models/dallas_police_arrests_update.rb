# frozen_string_literal: true

class DallasPoliceArrestsUpdate < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'dallas_police_arrests'
end
