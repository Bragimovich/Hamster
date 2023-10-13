# frozen_string_literal: true

class GuBarGuambarOrg < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'gu_bar_guambar_org'
  establish_connection(Storage[host: :db01, db: :lawyer_status]) 
end
    