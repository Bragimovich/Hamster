# frozen_string_literal: true

class AkSaacCaseAdditionalInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'ak_saac_case_additional_info'
end
