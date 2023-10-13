# frozen_string_literal: true

require_relative 'mississippi_inmateable'
class MississippiInmatesRun < ActiveRecord::Base
  include MississippiInmateable
end
