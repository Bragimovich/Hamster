# frozen_string_literal: true

class CongressNominationCommittee < ActiveRecord::Base
  self.table_name = 'congress_nomination_committee'
  include Hamster::Granary
  establish_connection(Storage[host: :db01, db: :usa_raw])

  has_many :persons, class_name: "CongressNominationPersons", foreign_key: :committee_id
end
