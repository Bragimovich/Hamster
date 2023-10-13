require_relative 'oh_schoolable'
class OhAttendance < ActiveRecord::Base
  include OhSchoolaable

  self.table_name = 'oh_attendance'
end
