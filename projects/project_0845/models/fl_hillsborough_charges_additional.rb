# frozen_string_literal: true

require_relative 'fl_hillsborough_inmateable'
class FlHillsboroughChargesAdditional < ActiveRecord::Base
  include FlHillsboroughInmateable

  self.table_name = 'fl_hillsborough_charges_additional'
end
