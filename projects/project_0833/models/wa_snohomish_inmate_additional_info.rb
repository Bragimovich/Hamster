# frozen_string_literal: true

require_relative 'wa_snohomish_inmateable'
class WaSnohomishInmateAdditionalInfo < ActiveRecord::Base
  include WaSnohomishInmateable

  self.table_name ='wa_snohomish_inmate_additional_info'
end
