# frozen_string_literal: true

class MilbGameAddInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :us_sports_milb_raw])
  self.table_name = 'milb_game_add_info'
  self.inheritance_column = :_type_disabled
end
