# frozen_string_literal: true
class KySafetyAuditMeasure < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ky_safety_audit_measures'
end