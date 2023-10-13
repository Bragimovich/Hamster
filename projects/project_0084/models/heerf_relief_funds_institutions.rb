# frozen_string_literal: true

class HEERFReliefInstitutions < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary

  self.table_name = 'heerf_relief_funds_institutions'
end
