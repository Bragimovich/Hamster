# frozen_string_literal: true

class IlDupageMugshots < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'il_dupage_mugshots'
  self.inheritance_column = :_type_disabled
end
