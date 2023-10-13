# frozen_string_literal: true

class CongressNominationActions < ActiveRecord::Base
  self.table_name = 'congress_nomination_actions'
  include Hamster::Granary
  establish_connection(Storage[host: :db01, db: :usa_raw]) 
end
