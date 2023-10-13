
class CasesWithPdfFromPipeline2 < ActiveRecord::Base
  self.table_name = 'cases_with_pdf_from_pipeline_2'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class NewCourtsTable < ActiveRecord::Base
  self.table_name = 'new_courts_table'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class UsCourtsTable < ActiveRecord::Base
  self.table_name = 'us_courts_table'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class CasesWithPdfFromCSV < ActiveRecord::Base
  self.table_name = 'cases_with_pdf_manually_from_csv'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class CasesWithPdfFromCSV_2 < ActiveRecord::Base
  self.table_name = 'cases_with_pdf_from_pipeline_1022' #'cases_with_pdf_manually_from_csv_2'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class StagingCourts < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'courts'
  establish_connection(Storage[host: :db01, db: :us_courts_staging_working_copy])
end