# frozen_string_literal: true

class MaineBar < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'me_maine_bar'
  self.logger = Logger.new(STDOUT)
end
