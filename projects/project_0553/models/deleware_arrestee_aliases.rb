# frozen_string_literal: true

class DEArresteeAlias < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :sex_offenders])
    self.table_name = 'deleware_arrestee_aliases'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new($stdout)
  end
