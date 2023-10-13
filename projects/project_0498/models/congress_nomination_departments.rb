# frozen_string_literal: true

class CongressNominationDepartments < ActiveRecord::Base
  self.table_name = 'congress_nomination_departments'
  include Hamster::Granary
  establish_connection(Storage[host: :db01, db: :usa_raw])

  has_many :persons, class_name: "CongressNominationPersons", foreign_key: :dept_id
end
