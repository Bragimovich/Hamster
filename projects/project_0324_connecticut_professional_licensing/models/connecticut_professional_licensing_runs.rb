# frozen_string_literal: true

class ConnecticutProfessionalLicensingRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'connecticut_professional_licensing_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
