# frozen_string_literal: true

require_relative 'al_inmateable'
class AlInmateAdditionalInfo < ActiveRecord::Base
  include AlInmateable

  self.table_name = 'al_inmate_additional_info'
end
