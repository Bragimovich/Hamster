# frozen_string_literal: true

class LimparGameFilled < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary

  self.table_name = 'games_filled'
  self.logger = Logger.new(STDOUT)
end

class LimparGameMatch < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary

  self.table_name = 'game_matches'
  self.logger = Logger.new(STDOUT)
end

class LimparBoxScore < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary

  self.table_name = 'box_scores'
  self.logger = Logger.new(STDOUT)
end

class LimparGameBoxScoreAdditional < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary

  self.table_name = 'game_box_score_additionals'
  self.logger = Logger.new(STDOUT)
end

