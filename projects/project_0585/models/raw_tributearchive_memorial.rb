# frozen_string_literal: true

require_relative 'raw_tributearchiveable'
class RawTributearchiveMemorial < ActiveRecord::Base
  include RawTributearchiveable

  self.table_name = 'raw_tributearchive_memorial'
end
