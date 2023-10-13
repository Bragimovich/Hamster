# frozen_string_literal: true

class IlCcccCaseInfo < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :us_court_cases])
    self.table_name = 'il_cccc_case_info'
    self.inheritance_column = :_type_disabled
end
