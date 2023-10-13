class RawTributearchiveRuns < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :obituary))
  self.table_name = 'raw_tributearchive_runs'
  include Hamster::Granary
end