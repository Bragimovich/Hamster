# frozen_string_literal: true

class UsCaseParty < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_courts))
  self.table_name = 'us_case_party'
  include Hamster::Granary
end
