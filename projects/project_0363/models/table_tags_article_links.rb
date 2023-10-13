# frozen_string_literal: true

class TableTAlinks < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
   
  self.table_name = 'us_dept_dos_boaa_tags_article_links'
  self.inheritance_column = :_type_disabled
end
