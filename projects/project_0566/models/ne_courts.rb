# frozen_string_literal: true
class NeCourt < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'ne_court__mcle_wcc_ne_gov'
  self.inheritance_column = :_type_disabled
end
