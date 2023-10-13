# frozen_string_literal: true
class Georgia_criminal_offenders_run < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'georgia_criminal_offenders_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
