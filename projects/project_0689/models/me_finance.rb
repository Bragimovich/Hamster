# frozen_string_literal: true
class MeFinance < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'me_finance'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
