# frozen_string_literal: true
class DeGeneralInfoRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'de_general_info_runs'
  self.inheritance_column = :_type_disabled
end
