# frozen_string_literal: true

class Ntsb < ActiveRecord::Base
  self.table_name = 'ntsb'
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.inheritance_column = :_type_disabled
end
