# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :sex_offenders])

  self.table_name = 'florida_runs'
  self.logger = Logger.new(STDOUT)
end
