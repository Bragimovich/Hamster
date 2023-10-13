# frozen_string_literal: true

class ArizonaRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'arizona_runs'
  self.inheritance_column = :_type_disabled
end
