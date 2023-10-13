# frozen_string_literal: true

class MilbScoreByInnings < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :us_sports_milb_raw])
  self.table_name = 'milb_score_by_innings'
  self.inheritance_column = :_type_disabled
end
