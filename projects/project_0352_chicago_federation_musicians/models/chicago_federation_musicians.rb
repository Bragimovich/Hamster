# frozen_string_literal: true

class Chicago_federation_musicians < ActiveRecord::Base
  self.table_name = 'chicago_federation_musicians'
  establish_connection(Storage[host: :db01, db: :il_raw])
  # establish_connection(Storage[host: :db09, db: :astorchak_test])
  self.logger = Logger.new(STDOUT)
  # self.inheritance_column = :_type_disabled
end
