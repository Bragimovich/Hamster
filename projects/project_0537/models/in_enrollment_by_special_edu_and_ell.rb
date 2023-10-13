# frozen_string_literal: true
class InEnrollmentBySpecialEduAndEll < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'in_enrollment_by_special_edu_and_ell'
  self.inheritance_column = :_type_disabled
end
