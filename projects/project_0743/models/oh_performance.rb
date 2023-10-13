require_relative 'oh_schoolable'
class OhPerformance < ActiveRecord::Base
  include OhSchoolaable

  self.table_name = 'oh_performance'
end
