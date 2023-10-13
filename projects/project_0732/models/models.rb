# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'us_sheriffs_info__runs'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class UsSheriffsInfo < ActiveRecord::Base
  self.table_name = 'us_sheriffs_info'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
