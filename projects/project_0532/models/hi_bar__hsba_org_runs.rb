# frozen_string_literal: true

class HsbaLawyerRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'hi_bar__hsba_org_runs'
  self.inheritance_column = :_type_disabled
end
  