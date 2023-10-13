# frozen_string_literal: true

class DallasPoliceIncidentsRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
end
