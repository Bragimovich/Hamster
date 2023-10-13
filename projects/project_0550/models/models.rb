class CaliforniaArrestee < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_arrestees'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaState < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_states'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaCity < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_cities'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaZip < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_zips'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaCoordinate < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_coordinates'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaAddress < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_addresses'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaArresteeAlias < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_arrestee_aliases'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaMugshot < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_mugshots'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaArresteeAdress < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_arrestees_address'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaOffense < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_offense'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaRiskAssessment < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_risk_assessment'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaMark < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_marks'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end

class CaliforniaRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary
  
  self.table_name = 'california_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end