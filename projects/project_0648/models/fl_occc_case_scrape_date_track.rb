# frozen_string_literal: true

class ScrapeDateTrack< ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'fl_occc_case_scrape_date_track'
  self.inheritance_column = :_type_disabled
end
 