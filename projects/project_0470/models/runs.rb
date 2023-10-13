# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'cl_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end
