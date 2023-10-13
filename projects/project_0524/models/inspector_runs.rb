class InspectorRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'inspector_general_reports_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end