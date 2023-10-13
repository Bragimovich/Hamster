class UsSchool < ActiveRecord::Base
    include Hamster::Loggable

    establish_connection(Storage[host: :db01, db: :us_schools_raw])
    self.table_name = 'us_schools'
    self.inheritance_column = :_type_disabled

    def self.get_all
        where(state: 'GA')
    end
end
