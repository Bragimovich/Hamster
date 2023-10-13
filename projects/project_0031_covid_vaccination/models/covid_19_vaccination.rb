# frozen_string_literal: true

class MainTable < ActiveRecord::Base
  self.table_name = 'covid_19_vaccination'
  establish_connection(Storage[host: :db01, db: :usa_raw])


end
