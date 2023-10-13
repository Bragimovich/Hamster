# frozen_string_literal: true

class MiCampFinanceContribution < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'michigan_campaign_finance_contributions'
  self.inheritance_column = :_type_disabled
end
