# frozen_string_literal: true

class MeScCaseActivities < ActiveRecord::Base
  include MeScCaseable

  self.table_name = 'me_sc_case_activities'
end

