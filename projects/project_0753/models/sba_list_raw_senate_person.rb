# frozen_string_literal: true
class Sba_List_Raw_Senate_Person < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :usa_raw])
    self.table_name = 'sba_list_scorecard_raw_senate_person'
    self.inheritance_column = :_type_disabled
end
