# frozen_string_literal: true
class VaRawScheduleB < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'VA_RAW_SCHEDULEB'
  self.inheritance_column = :_type_disabled
end
