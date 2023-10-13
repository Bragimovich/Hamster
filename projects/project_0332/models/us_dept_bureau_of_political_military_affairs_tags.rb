# frozen_string_literal: true

class UsDeptBureauOfPoliticalMilitaryAffairsTags < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'us_dept_bureau_of_political_military_affairs_tags'
  self.logger = Logger.new(STDOUT)
end
