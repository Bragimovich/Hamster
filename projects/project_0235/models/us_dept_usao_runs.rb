# frozen_string_literal: true
class USAORuns < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'us_dept_usao_articles_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
