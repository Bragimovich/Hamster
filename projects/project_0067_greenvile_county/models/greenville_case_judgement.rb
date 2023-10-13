# frozen_string_literal: true

class GreenvilleCaseJudgement < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  self.table_name = 'greenville_case_judgment'
  include Hamster::Granary
end
