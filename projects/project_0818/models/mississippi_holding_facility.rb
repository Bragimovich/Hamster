# frozen_string_literal: true

require_relative 'mississippi_inmateable'
class MississippiHoldingFacility < ActiveRecord::Base
  include MississippiInmateable

  belongs_to :mississippi_arrest, foreign_key: :arrest_id
end
