# frozen_string_literal: true

class DelewareArresteesRuns < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :sex_offenders])
    self.table_name = 'deleware_arrestees_runs'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new($stdout)
  end
