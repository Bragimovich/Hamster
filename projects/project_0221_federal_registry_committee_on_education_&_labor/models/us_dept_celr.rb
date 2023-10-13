# frozen_string_literal: true

class Celr < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])

  self.table_name = 'us_dept_celr'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
