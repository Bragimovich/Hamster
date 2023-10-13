# frozen_string_literal: true

class IllinoisSexOffendersRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'illinois_sex_offenders_run'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new($stdout)
end
