# frozen_string_literal: true
require 'strip_attributes'

class Illinois_runs < ActiveRecord::Base
  strip_attributes
  self.table_name = 'Illinois_runs'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end