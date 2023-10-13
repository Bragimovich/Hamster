# frozen_string_literal: true

class IlWillCrimeRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
  include Hamster::Granary

  self.table_name = 'il_will__runs'
end





