# frozen_string_literal: true

class KyEnrollment < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  include Hamster::Granary

  self.table_name = 'ky_enrollment'
  self.logger = Logger.new(STDOUT)
end
