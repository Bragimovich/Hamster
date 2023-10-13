# Lower Court
class AdditionalInfo < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary

  self.table_name = 'sc_saac_case_additional_info'
  self.logger = Logger.new(STDOUT)
end