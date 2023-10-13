# frozen_string_literal: true
require 'strip_attributes'
# db01.lawyer_status.Illinois
class Illinois_prod < ActiveRecord::Base
  strip_attributes
  self.table_name = 'Illinois'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end