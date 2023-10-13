# frozen_string_literal: true

class UsCourtsTable < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :usa_raw))
  self.table_name = 'us_courts_table'
  include Hamster::Granary
end
