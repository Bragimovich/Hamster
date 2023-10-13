# frozen_string_literal: true
class Sba_List_Scorecard_Raw_Person < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :usa_raw])
    self.table_name = 'sba_list_scorecard_raw_person'
    self.inheritance_column = :_type_disabled
end
