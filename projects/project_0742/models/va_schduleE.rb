# frozen_string_literal: true
class VaRawScheduleE < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'VA_RAW_SCHEDULEE'
  self.inheritance_column = :_type_disabled
end
