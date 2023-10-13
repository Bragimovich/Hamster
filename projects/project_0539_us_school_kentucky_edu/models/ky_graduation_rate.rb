# frozen_string_literal: true

class KyGraduationRate < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'ky_graduation_rate'
end
  
