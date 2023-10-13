# frozen_string_literal: true

require_relative 'wa_snohomish_inmateable'
class WaSnohomishInmatesRun < ActiveRecord::Base
  include WaSnohomishInmateable
end
