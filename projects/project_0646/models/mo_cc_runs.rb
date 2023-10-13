# frozen_string_literal: true
class MoRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'mo_cc_runs'
  self.inheritance_column = :_type_disabled
end
