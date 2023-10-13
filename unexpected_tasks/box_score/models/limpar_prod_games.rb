# frozen_string_literal: true

class LimparStatistic < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :limpar_prod, db: :limpar])
  include Hamster::Granary

  self.table_name = 'statistics'
  self.logger = Logger.new(STDOUT)
end

class LimparSportStatistic < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :limpar_prod, db: :limpar])
  include Hamster::Granary

  self.table_name = 'sport_statistics'
  self.logger = Logger.new(STDOUT)
end

class LimparGame < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :limpar_prod, db: :limpar])
  include Hamster::Granary

  self.table_name = 'games'
  self.logger = Logger.new(STDOUT)
end

class LimparTeam < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :limpar_prod, db: :limpar])
  include Hamster::Granary

  self.table_name = 'teams'
  self.logger = Logger.new(STDOUT)
end

class LimparSportMatch < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :limpar_prod, db: :limpar])
  include Hamster::Granary

  self.table_name = 'sport_matches'
  self.logger = Logger.new(STDOUT)
end
