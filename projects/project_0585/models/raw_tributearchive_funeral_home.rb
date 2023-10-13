# frozen_string_literal: true

require_relative 'raw_tributearchiveable'
class RawTributearchiveFuneralHome < ActiveRecord::Base
  include RawTributearchiveable

  self.table_name = 'raw_tributearchive_funeral_home'
end
