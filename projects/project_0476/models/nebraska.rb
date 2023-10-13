# frozen_string_literal: true
class Nebraska < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'ne_bar__nebar_reliaguide_com'
  self.inheritance_column = :_type_disabled
end
