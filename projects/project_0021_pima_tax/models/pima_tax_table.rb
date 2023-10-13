# frozen_string_literal: true

class PimaTaxpayers < ActiveRecord::Base
  self.table_name = 'pima_county_arizona_delinquent_re_taxpayers'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
