# frozen_string_literal: true

class NIFAuthority < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'ne_invest_finance_authority'
  self.logger = Logger.new(STDOUT)
end
