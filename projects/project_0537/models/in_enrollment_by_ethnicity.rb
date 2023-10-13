# frozen_string_literal: true
class InEnrollmentByEthnicity < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'in_enrollment_by_ethnicity'
  self.inheritance_column = :_type_disabled
end
