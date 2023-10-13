# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'sc_bar_scbar_org__runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end
