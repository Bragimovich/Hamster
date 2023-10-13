# frozen_string_literal: true

class UsDeptEnergyAndCommerceCategoriesArticleLinks < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'us_dept_energy_and_commerce_categories_article_links'
  self.logger = Logger.new(STDOUT)
end
