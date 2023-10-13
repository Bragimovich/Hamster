# frozen_string_literal: true
class Sba_List_Raw_Activities < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :usa_raw])
    self.table_name = 'sba_list_scorecard_raw_activities'
    self.inheritance_column = :_type_disabled
end
