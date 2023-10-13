# frozen_string_literal: true
class InEnrollmentByGrade < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'in_enrollment_by_grade'
  self.inheritance_column = :_type_disabled
end
