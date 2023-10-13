# frozen_string_literal: true

require_relative 'md_case_concern'
class MdDcCaseJudgment < ActiveRecord::Base
  include MdCaseConcern

  self.table_name = 'md_dccc_case_judgment'
end
