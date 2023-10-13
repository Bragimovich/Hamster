require_relative 'oh_schoolable'
class OhGifted < ActiveRecord::Base
  include OhSchoolaable

  self.table_name = 'oh_gifted'
end
