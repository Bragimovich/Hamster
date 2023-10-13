# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'or_osbar_runs'
  include Hamster::Granary
  establish_connection(Storage[host: :db01, db: :lawyer_status]) 
end
