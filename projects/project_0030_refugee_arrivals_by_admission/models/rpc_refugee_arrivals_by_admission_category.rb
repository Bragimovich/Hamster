# frozen_string_literal: true

class RPCRefugeeArrivalsByAdmissionCategory < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'RPC_refugee_arrivals_by_admission_category'
end
