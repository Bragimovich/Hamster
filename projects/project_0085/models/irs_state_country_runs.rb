require_relative 'task85_csv_save'
class IRSStateCountryRuns < ActiveRecord::Base
  establish_connection(Storage[host: ((LOCAL_HOST_DEV)? :dbL01 : :db01), db: :usa_raw])
  extend Task85CsvSave
  include Hamster::Granary
  self.table_name = 'IRS_state_county_runs'
end
