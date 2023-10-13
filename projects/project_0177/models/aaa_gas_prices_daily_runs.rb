class AaaGasPricesDailyRuns < ActiveRecord::Base
  include Hamster::Loggable
  include Hamster::Granary
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
