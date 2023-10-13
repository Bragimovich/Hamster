# frozen_string_literal: true

class USACases < ActiveRecord::Base
  self.table_name = 'cdc_usa_daily_case_counts'
  establish_connection(Storage[host: :db01, db: :monkeypox])
end
