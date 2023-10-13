# frozen_string_literal: true

class PrlogFiles < ActiveRecord::Base
  self.table_name = 'prlog_files'
  establish_connection(Storage[host: :db02, db: :press_releases])
end
