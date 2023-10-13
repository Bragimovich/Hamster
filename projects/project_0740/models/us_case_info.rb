# frozen_string_literal: true

class UsCaseInfo < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :us_courts])
    self.table_name = 'us_case_info'
    self.inheritance_column = :_type_disabled
end
