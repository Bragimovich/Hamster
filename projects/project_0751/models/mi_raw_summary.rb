# frozen_string_literal: true
class MIRAWSummary < ActiveRecord::Base
  establish_connection(Storage[host: :dbhatri, db: :dbhatri])
  self.table_name = 'MI_RAW_summary'
  self.inheritance_column = :_type_disabled
end
