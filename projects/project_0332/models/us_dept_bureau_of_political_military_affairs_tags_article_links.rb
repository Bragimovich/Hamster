# frozen_string_literal: true

class UsDeptBureauOfPoliticalMilitaryAffairsTagsArticleLinks < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'us_dept_bureau_of_political_military_affairs_tags_article_links'
  self.logger = Logger.new(STDOUT)
end
