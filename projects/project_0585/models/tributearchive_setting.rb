# frozen_string_literal: true

require_relative 'raw_tributearchiveable'
class TributearchiveSetting < ActiveRecord::Base
  include RawTributearchiveable

  self.table_name = 'tributearchive_settings'
end
