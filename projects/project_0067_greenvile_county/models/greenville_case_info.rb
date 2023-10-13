# frozen_string_literal: true

class GreenvilleCaseInfo < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  self.table_name = 'greenville_case_info'
  include Hamster::Granary
end
