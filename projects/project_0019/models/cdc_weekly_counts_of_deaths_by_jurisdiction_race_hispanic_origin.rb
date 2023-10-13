# frozen_string_literal: true

class CDCWeeklyCountsOfDeathsByJurisdictionRaceHispanicOrigin < ActiveRecord::Base
  # self.inheritance_column = :some_other
  self.table_name = 'cdc_weekly_counts_of_deaths_by_jurisdiction_race_hispanic_origin'
  establish_connection(Storage.use(host: :db01, db: :usa_raw))
end


