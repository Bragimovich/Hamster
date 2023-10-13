# frozen_string_literal: true

class MCFExpenditures < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_fin_cc_raw])
  self.table_name = 'minnesota_campaign_finance_expenditures_csv'
  self.inheritance_column = :_type_disabled
end
