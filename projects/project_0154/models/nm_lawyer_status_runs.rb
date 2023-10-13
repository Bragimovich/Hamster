# frozen_string_literal: true

class NMLawyerStatusRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'nm_bar_sbnm_org_runs'
end
