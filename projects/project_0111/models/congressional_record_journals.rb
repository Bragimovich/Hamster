# frozen_string_literal: true

class CongressionalRecordJournals < ActiveRecord::Base
  self.table_name = 'congressional_record_journals'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
