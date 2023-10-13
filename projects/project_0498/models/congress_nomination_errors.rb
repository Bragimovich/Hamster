# frozen_string_literal: true

class CongressNominationErrors < ActiveRecord::Base
  self.table_name = 'congress_nomination_errors'
  include Hamster::Granary
  establish_connection(Storage[host: :db01, db: :usa_raw]) 
end
