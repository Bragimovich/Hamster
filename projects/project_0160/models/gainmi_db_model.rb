# frozen_string_literal: true

class GeorgiaLawyerStatus < ActiveRecord::Base
  self.table_name = 'georgia'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end

class GeorgiaLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'georgia_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end


class IndianaLawyerStatus < ActiveRecord::Base
  self.table_name = 'indiana'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end

class IndianaLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'indiana_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end


class MichiganLawyerStatus < ActiveRecord::Base
  self.table_name = 'michigan'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end

class MichiganLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'michigan_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end