# frozen_string_literal: true

class MiCampFinanceContributor < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'michigan_campaign_finance_contributors'
  self.inheritance_column = :_type_disabled
end
