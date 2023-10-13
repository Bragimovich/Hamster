class AlGeneralInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'al_general_info'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
  include Hamster::Granary

  def self.update_district_code(id, district_code)
    self.connection.execute("update al_general_info set number='#{district_code}' where id=#{id}")
  end
end