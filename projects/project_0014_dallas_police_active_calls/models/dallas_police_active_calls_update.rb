# frozen_string_literal: true

class DallasPoliceActiveCallsUpdate < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'dallas_police_active_calls'
end
