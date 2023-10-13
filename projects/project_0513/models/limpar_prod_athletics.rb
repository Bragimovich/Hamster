# frozen_string_literal: true

class LimparAthleticRoster < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :limpar_prod, db: :limpar])
  include Hamster::Granary

  self.table_name = 'athletic_rosters'
  self.logger = Logger.new(STDOUT)
end

class LimparAthleticSeason < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :limpar_prod, db: :limpar])
  include Hamster::Granary

  self.table_name = 'athletic_seasons'
  self.logger = Logger.new(STDOUT)
end

class LimparAthleticSportAdditionalField < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :limpar_prod, db: :limpar])
  include Hamster::Granary

  self.table_name = 'athletic_sport_additional_fields'
  self.logger = Logger.new(STDOUT)
end

class LimparAthleticSport < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :limpar_prod, db: :limpar])
  include Hamster::Granary

  self.table_name = 'athletic_sports'
  self.logger = Logger.new(STDOUT)
end
