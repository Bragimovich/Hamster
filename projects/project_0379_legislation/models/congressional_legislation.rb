# frozen_string_literal: true

class CongressionalLegislationInfo < ActiveRecord::Base
  self.table_name = 'congressional_legislation_info'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalLegislationActions < ActiveRecord::Base
  self.table_name = 'congressional_legislation_actions'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalLegislationActionsOverview < ActiveRecord::Base
  self.table_name = 'congressional_legislation_actions_overview'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalLegislationCommittees < ActiveRecord::Base
  self.table_name = 'congressional_legislation_committees'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalLegislationCosponsors < ActiveRecord::Base
  self.table_name = 'congressional_legislation_cosponsors'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalLegislationRelatedBills < ActiveRecord::Base
  self.table_name = 'congressional_legislation_related_bills'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalLegislationSubjects < ActiveRecord::Base
  self.table_name = 'congressional_legislation_subjects'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalLegislationTexts < ActiveRecord::Base
  self.table_name = 'congressional_legislation_texts'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalLegislationCommitteesFederalSites < ActiveRecord::Base
  self.table_name = 'congressional_legislation_committees_federal_sites'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class CongressionalLegislationCommitteesFederalSites < ActiveRecord::Base
  self.table_name = 'congressional_legislation_committees_federal_sites'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class CongressionalLegislationSponsorsFederalSites < ActiveRecord::Base
  self.table_name = 'congressional_legislation_sponsors_uniq'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalRecordSenateMembers < ActiveRecord::Base
  self.table_name = 'us_congress_senate_members'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalRecordHouseRPMembers < ActiveRecord::Base
  self.table_name = 'us_congress_house_members'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end