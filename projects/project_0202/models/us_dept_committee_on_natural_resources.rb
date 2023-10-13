# frozen_string_literal: true

class UsDeptCommitteeOnNaturalResources < ActiveRecord::Base
  self.table_name = 'us_dept_committee_on_natural_resources'
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.logger = Logger.new(STDOUT)
  self.inheritance_column = :_type_disabled
end
