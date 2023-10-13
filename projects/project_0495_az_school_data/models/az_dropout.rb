# frozen_string_literal: true

class AzDropout < ActiveRecord::Base
  self.table_name = 'az_dropout'
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
end