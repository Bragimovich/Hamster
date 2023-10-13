# frozen_string_literal: true

require_relative 'mississippi_inmateable'
class MississippiInmateAdditionalInfo < ActiveRecord::Base
  include MississippiInmateable

  self.table_name = 'mississippi_inmate_additional_info'
end
