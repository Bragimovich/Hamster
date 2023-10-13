# frozen_string_literal: true
require 'strip_attributes'

class UsDhs < ActiveRecord::Base
  strip_attributes
  self.table_name = 'us_dhs'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
end