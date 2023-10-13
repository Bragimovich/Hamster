# frozen_string_literal: true

require_relative 'raw_tributearchiveable'
class RawTributearchiveCeoSetting < ActiveRecord::Base
  include RawTributearchiveable

  self.table_name = 'raw_tributearchive_ceo_settings'
end
