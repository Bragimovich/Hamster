# frozen_string_literal: true

require_relative 'nc_assessmentable'
class NcUsaRaw < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.establish_connection(Storage[host: :db01, db: :usa_raw])
end
