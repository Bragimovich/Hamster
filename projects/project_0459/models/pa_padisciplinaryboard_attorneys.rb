# frozen_string_literal: true
class PaPadisciplinaryboardAttorneys < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'pa_padisciplinaryboard_attorneys'
  self.inheritance_column = :_type_disabled
end
