# frozen_string_literal: true

require_relative 'fl_hillsborough_inmateable'
class FlHillsboroughInmateAdditionalInfo < ActiveRecord::Base
  include FlHillsboroughInmateable

  self.table_name = 'fl_hillsborough_inmate_additional_info'
end
