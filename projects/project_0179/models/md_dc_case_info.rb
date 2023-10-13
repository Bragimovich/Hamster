# frozen_string_literal: true

require_relative 'md_case_concern'
class MdDcCaseInfo < ActiveRecord::Base
  include MdCaseConcern

  self.table_name = 'md_dccc_case_info'
end
