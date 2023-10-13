# frozen_string_literal: true

class PledgeTeachTruthRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary

  self.table_name = 'pledge_to_teach_the_truth_runs'
end




