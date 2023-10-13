# frozen_string_literal: true

require_relative 'fl_hillsborough_inmateable'
class FlHillsboroughCourtHearing < ActiveRecord::Base
  include FlHillsboroughInmateable
end
