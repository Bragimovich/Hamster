# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'ny_newyork_bar_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status]) 
end
  