# frozen_string_literal: true

class UsDeptDoaAphisPrograms < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'us_dept_doa_aphis_programs'
  self.inheritance_column = :_type_disabled
end
