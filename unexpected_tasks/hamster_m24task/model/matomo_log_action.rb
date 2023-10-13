class MatomoLogAction < ActiveRecord::Base
  self.table_name = "matomo_log_action"
  self.inheritance_column = :_type_disabled
  establish_connection(Storage.use(host: :dbRS, db: :mat))
end
