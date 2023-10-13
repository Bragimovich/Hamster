# frozen_string_literal: true

class MaineBarRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status]) # db02 localhost
  self.table_name = 'me_maine_bar_runs'
  self.logger = Logger.new(STDOUT)
end
