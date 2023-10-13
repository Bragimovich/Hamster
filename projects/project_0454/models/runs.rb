# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'runs'
  establish_connection(Storage[host: :db01, db: :monkeypox])
end
