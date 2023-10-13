# frozen_string_literal: true
class NyCandidate < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'ny_nysboe_filers_candidates'
  self.inheritance_column = :_type_disabled
end
