# frozen_string_literal: true

class DallasPoliceIncidentsUpdate < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.inheritance_column = 'runtime_class'
  include Hamster::Granary
  
  self.table_name = 'dallas_police_incidents'
end
