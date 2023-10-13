# frozen_string_literal: true

class GeorgiaSexOffendersRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :sex_offenders])
  include Hamster::Granary

  self.table_name = 'Georgia_runs'
end