# frozen_string_literal: true

class UsDeptCftcCategories < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'us_dept_cftc_categories'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
