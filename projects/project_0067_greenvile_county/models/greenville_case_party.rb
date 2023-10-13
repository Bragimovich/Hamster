# frozen_string_literal: true

class GreenvilleCaseParty < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  self.table_name = 'greenville_case_party'
  include Hamster::Granary
end
