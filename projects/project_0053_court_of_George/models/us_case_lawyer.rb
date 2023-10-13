# frozen_string_literal: true

class UsCaseLawyer < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :usa_raw))
  self.table_name = 'us_case_lawyer'
  include Hamster::Granary
end
