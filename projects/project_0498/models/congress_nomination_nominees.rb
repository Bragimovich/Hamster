# frozen_string_literal: true

class CongressNominationNominees < ActiveRecord::Base
  self.table_name = 'congress_nomination_nominees'
  include Hamster::Granary
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
