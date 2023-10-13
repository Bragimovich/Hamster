# frozen_string_literal: true

class MeScCaseInfo < ActiveRecord::Base
  include MeScCaseable

  self.table_name = 'me_sc_case_info'
end
