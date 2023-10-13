# frozen_string_literal: true

class USCourtsCaseSummaryLinks < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_courts])
  include Hamster::Granary
  self.inheritance_column = :_type_disabled

  self.table_name = 'us_courts_case_summary_court_links'
end


