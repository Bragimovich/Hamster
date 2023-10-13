# frozen_string_literal: true

require_relative 'wa_snohomish_inmateable'
class WaSnohomishCourtHearing < ActiveRecord::Base
  include WaSnohomishInmateable
end
