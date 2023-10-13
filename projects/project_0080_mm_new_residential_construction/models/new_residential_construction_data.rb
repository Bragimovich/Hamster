# frozen_string_literal: true

class NewResidentialConstructionData < ActiveRecord::Base
  establish_connection(Storage[host: :db13, db: :usa_raw])
  include Hamster::Granary
  self.table_name = 'mm_new_residential_construction_data'
end
