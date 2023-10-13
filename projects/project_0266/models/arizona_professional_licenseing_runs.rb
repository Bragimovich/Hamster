# frozen_string_literal: true
class ArizonaProfessionalLicenseingRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'arizona_professional_licenseing_runs'
  self.inheritance_column = :_type_disabled
end
