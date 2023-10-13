# frozen_string_literal: true

class FloridaMakrs < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary

  self.table_name = 'florida_makrs'
  self.logger = Logger.new(STDOUT)
end
