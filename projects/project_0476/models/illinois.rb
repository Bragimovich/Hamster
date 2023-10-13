# frozen_string_literal: true
class Illinois < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'il_bar__isba_reliaguide_com'
  self.inheritance_column = :_type_disabled
end
