# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'nppes_npi_registry_runs'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
