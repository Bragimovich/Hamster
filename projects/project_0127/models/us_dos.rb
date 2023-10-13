# frozen_string_literal: true

class UsDos < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  self.table_name = 'us_dos'
  self.inheritance_column = :_type_disabled
end
