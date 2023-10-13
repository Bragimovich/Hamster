# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'il_chicago_arrests__runs'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
