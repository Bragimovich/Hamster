# frozen_string_literal: true

class CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeath < ActiveRecord::Base
  # self.inheritance_column = :some_other
  self.table_name = 'cdc_weekly_counts_of_death_by_jurisdiction_and_cause_of_death'
  establish_connection(Storage.use(host: :db01, db: :usa_raw))
end

