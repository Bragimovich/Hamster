# frozen_string_literal: true

class PrlogTags < ActiveRecord::Base
  self.table_name = 'prlog_tags'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
