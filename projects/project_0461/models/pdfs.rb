# frozen_string_literal: true

class Pdfs < ActiveRecord::Base
  self.table_name = 'pdfs'
  establish_connection(Storage[host: :db01, db: :monkeypox])
end
