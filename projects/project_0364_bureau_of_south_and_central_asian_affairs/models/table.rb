# frozen_string_literal: true

class Table < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  
  self.table_name = 'us_dept_dos_boscaa'
  self.inheritance_column = :_type_disabled
end
