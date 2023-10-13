# frozen_string_literal: true

class UsDeptEnergyAndCommerce < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'us_dept_energy_and_commerce'
  self.logger = Logger.new(STDOUT)

  def self.udpate_touched_run_id(id,touched_run_id)
    self.connection.execute("update us_dept_energy_and_commerce set touched_run_id=#{touched_run_id} where id=#{id}")
  end

  def self.mark_deleted(id)
    self.connection.execute("update us_dept_energy_and_commerce set deleted=1 where id=#{id}")
  end
end
