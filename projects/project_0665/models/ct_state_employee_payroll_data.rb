# frozen_string_literal: true
class CtStateEmployeePayroll < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :state_salaries__raw])
    self.table_name = 'ct_state_employee_payroll_data'
    self.inheritance_column = :_type_disabled
end
