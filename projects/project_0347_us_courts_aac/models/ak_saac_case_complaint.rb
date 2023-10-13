# frozen_string_literal: true

class AkSaacCaseComplaint < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'ak_saac_case_complaint'
end
