# frozen_string_literal: true

class WorldCases < ActiveRecord::Base
  self.table_name = 'powerbi_world_daily_case_counts'
  establish_connection(Storage[host: :db01, db: :monkeypox])
end
