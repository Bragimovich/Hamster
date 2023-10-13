# frozen_string_literal: true
class MeGraduation < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'me_graduation'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
