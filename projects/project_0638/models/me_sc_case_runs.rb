# frozen_string_literal: true

class MeScCaseRuns < ActiveRecord::Base
  include MeScCaseable

  self.table_name = 'me_sc_case_runs'
end

