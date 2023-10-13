# frozen_string_literal: true

class IaCourtOrgRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'ia_court__iacourtcommissions_org_runs'
  self.inheritance_column = :_type_disabled
end
  