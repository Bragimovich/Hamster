# frozen_string_literal: true

require_relative 'mississippi_inmateable'
class MississippiMugshot < ActiveRecord::Base
  include MississippiInmateable
end
