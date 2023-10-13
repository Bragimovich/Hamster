# frozen_string_literal: true

class CongressNominationPersons < ActiveRecord::Base
  self.table_name = 'congress_nomination_persons'
  include Hamster::Granary
  establish_connection(Storage[host: :db01, db: :usa_raw])


  belongs_to :department, class_name: "CongressNominationDepartments", foreign_key: :dept_id
  belongs_to :committee, class_name: "CongressNominationCommittee", foreign_key: :committee_id
end
