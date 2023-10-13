# frozen_string_literal: true

require_relative 'fl_hillsborough_inmateable'
class FlHillsboroughHoldingFacility < ActiveRecord::Base
  include FlHillsboroughInmateable
end
