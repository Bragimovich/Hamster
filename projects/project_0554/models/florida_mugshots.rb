# frozen_string_literal: true

class FloridaMugshots < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary

  self.table_name = 'florida_mugshots'
  self.logger = Logger.new(STDOUT)
end
