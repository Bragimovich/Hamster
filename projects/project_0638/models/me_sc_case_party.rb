# frozen_string_literal: true

class MeScCaseParty < ActiveRecord::Base
  include MeScCaseable
  
  self.table_name = 'me_sc_case_party'
end
