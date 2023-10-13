# frozen_string_literal: true

class OhProfessional < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
 
  self.table_name = 'oh_professional_licences'
  self.inheritance_column = :_type_disabled
end
