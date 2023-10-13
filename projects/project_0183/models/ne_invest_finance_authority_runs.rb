# frozen_string_literal: true

class NIFARuns < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'ne_invest_finance_authority_runs'
  self.logger = Logger.new(STDOUT)

end