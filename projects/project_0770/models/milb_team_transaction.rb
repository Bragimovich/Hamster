# frozen_string_literal: true

class MilbTeamTransaction < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :us_sports_milb_raw])
  self.table_name = 'milb_team_transactions'
  self.inheritance_column = :_type_disabled
end
