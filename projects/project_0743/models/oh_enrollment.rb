require_relative 'oh_schoolable'
class OhEnrollment < ActiveRecord::Base
  include OhSchoolaable

  self.table_name = 'oh_enrollment'
end
