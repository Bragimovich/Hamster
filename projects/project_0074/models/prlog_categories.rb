# frozen_string_literal: true

class PrlogCategories < ActiveRecord::Base
  self.table_name = 'prlog_categories'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
