require_relative 'oh_schoolable'
class OhGraduation < ActiveRecord::Base
  include OhSchoolaable

  self.table_name = 'oh_graduation'
end
