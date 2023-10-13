class TaxExempt < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary

  self.table_name = 'us_tax_exempt_organizations__publication_78_EXP'
  self.logger = Logger.new(STDOUT)
end

class TaxExemptRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary

  self.table_name = 'us_tax_exempt_organizations__publication_78_runs_EXP'
  self.logger = Logger.new(STDOUT)
end