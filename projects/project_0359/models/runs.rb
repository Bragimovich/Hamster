# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'il_professional_licenses__runs'
  establish_connection(Storage[host: :db01, db: :il_raw])
end
