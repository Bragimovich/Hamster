# frozen_string_literal: true

class Organization < ActiveRecord::Base
  self.table_name = 'opensecrets__organizations'
  establish_connection(Storage[host: :db01, db: :woke_project])
end
