class AzBarAzbarOrgRun < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  include Hamster::Granary

  self.table_name = 'az_bar_azbar_org_runs'
  self.logger = Logger.new(STDOUT)
end
