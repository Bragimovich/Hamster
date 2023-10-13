# frozen_string_literal: true

class GreenvilleCaseActivities < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  self.table_name = 'greenville_case_activities'
  include Hamster::Granary
end
