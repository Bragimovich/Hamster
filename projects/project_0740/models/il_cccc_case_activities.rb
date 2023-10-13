# frozen_string_literal: true

class IlCcccCaseActivities < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :us_court_cases])
    self.table_name = 'il_cccc_case_activities'
    self.inheritance_column = :_type_disabled
end
