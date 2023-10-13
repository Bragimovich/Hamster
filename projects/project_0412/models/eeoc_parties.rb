# frozen_string_literal: true
class EeocParties < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'eeoc_parties'
  self.inheritance_column = :_type_disabled
end
