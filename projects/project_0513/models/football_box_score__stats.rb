# frozen_string_literal: true

class FootballPassingStats < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary
  
  self.table_name = 'football__passing_stats'
  self.logger = Logger.new(STDOUT)
end

class FootballRushingStats < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary

  self.table_name = 'football__rushing_stats'
  self.logger = Logger.new(STDOUT)
end

class FootballReceivingStats < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary

  self.table_name = 'football__receiving_stats'
  self.logger = Logger.new(STDOUT)
end

class FootballDefensiveStats < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary

  self.table_name = 'football__defensive_stats'
  self.logger = Logger.new(STDOUT)
end

class FootballPlayerStats < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_box_score])
  include Hamster::Granary

  self.table_name = 'football__player_stats'
  self.logger = Logger.new(STDOUT)
end
