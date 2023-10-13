# frozen_string_literal: true

require_relative 'wa_snohomish_inmateable'
class WaSnohomishChargesAdditional < ActiveRecord::Base
  include WaSnohomishInmateable

  self.table_name = 'wa_snohomish_charges_additional'
end
