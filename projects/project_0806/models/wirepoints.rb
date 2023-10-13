# frozen_string_literal: true

class Wirepoint < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'wirepoints'
  self.inheritance_column = :_type_disabled
end
