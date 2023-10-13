# frozen_string_literal: true

require_relative 'al_inmateable'
class AlInmatesRun < ActiveRecord::Base
  include AlInmateable
end
