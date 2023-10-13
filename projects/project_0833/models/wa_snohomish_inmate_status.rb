# frozen_string_literal: true

require_relative 'wa_snohomish_inmateable'
class WaSnohomishInmateStatus < ActiveRecord::Base
  include WaSnohomishInmateable
end
