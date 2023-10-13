# frozen_string_literal: true

class KyPublicRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])

  self.table_name = 'ky_public_employee_salaries_runs'
  self.inheritance_column = :_type_disabled
end
