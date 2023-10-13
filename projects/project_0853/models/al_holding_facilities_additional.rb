# frozen_string_literal: true

require_relative 'al_inmateable'
class AlHoldingFacilitiesAdditional < ActiveRecord::Base
  include AlInmateable

  self.table_name = 'al_holding_facilities_additional'
end
