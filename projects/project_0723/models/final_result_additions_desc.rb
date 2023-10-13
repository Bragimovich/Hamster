# frozen_string_literal: true

class FinalResultAdditionsDesc < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :us_sports_raw])
  self.table_name = 'final_result_additions_desc'
  self.inheritance_column = :_type_disabled
end
