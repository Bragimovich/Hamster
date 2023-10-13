# frozen_string_literal: true
class EcocBriefs < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'eeoc_briefs'
  self.inheritance_column = :_type_disabled
end
