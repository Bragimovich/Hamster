# frozen_string_literal: true

class FLSAACCasePartiesRaw < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary
  self.table_name = 'fl_saac_case_parties_raw'
end

class FLSAACCaseRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary
  self.table_name = 'fl_saac_case_runs'
end


class FLSAACCaseActivities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary
  self.table_name = 'fl_saac_case_activities'
end


class FLSAACCaseInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary
  self.table_name = 'fl_saac_case_info'
end


class FLSAACCaseParty < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary
  self.table_name = 'fl_saac_case_party'
end

class FLSAACCaseAdditionalInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary
  self.table_name = 'fl_saac_case_additional_info'
end

class FLSAACCasePDFsOnAWS < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary
  self.table_name = 'fl_saac_case_pdfs_on_aws'
end

class FLSAACCaseRelationsActivityPDF < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary
  self.table_name = 'fl_saac_case_relations_activity_pdf'
end
