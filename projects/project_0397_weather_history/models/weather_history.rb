# frozen_string_literal: true

class WeatherHistory < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'weather_history'
end

class WeatherHistoryCities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'weather_history_cities'
end


class USAAdministrativeDivisionCounties < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :hle_resources_readonly_sync])
  self.table_name = 'usa_administrative_division_counties_places_matching'
end
