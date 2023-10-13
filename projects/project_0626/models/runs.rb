# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status])

  self.table_name = 'ct_court__jud_ct_gov_runs'
  self.logger = Logger.new(STDOUT)
end
