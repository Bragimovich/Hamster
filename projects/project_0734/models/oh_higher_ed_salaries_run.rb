class OhHigherEdSalariesRun < ActiveRecord::Base
    include Hamster::Loggable
    
    establish_connection(Storage[host: :db01, db: :state_salaries__raw])
    self.table_name = 'oh_higher_ed_salaries_runs'
    self.inheritance_column = :_type_disabled
end
