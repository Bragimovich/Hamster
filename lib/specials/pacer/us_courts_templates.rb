# frozen_string_literal: true

class UsCourtTemplates < ActiveRecord::Base
  self.table_name = 'us_courts_templates'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
