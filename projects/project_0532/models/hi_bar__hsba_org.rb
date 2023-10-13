# frozen_string_literal: true

class HsbaLawyer < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'hi_bar__hsba_org'
  self.inheritance_column = :_type_disabled
end
  