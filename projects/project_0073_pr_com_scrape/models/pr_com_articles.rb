# frozen_string_literal: true

class PrComArticles < ActiveRecord::Base
  self.table_name = 'pr_com_articles'
  establish_connection(Storage[host: :db02, db: :press_releases])
  # establish_connection(Storage[host: :localhost, db: :press_releases])
  self.logger = Logger.new(STDOUT)
  self.inheritance_column = :_type_disabled
end