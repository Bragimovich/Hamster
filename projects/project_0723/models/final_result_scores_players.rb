# frozen_string_literal: true

class FinalResultScorePlayer < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :us_sports_raw])
  self.table_name = 'final_result_scores_players'
  self.inheritance_column = :_type_disabled
end
  