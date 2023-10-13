# frozen_string_literal: true

class OpenSocietyFoundationsAwardedGrants < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :woke_project])
  self.table_name = 'open_society_foundations'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
  