# frozen_string_literal: true

require_relative 'md_case_concern'
class MdAcCaseInfo < ActiveRecord::Base
  include MdCaseConcern

  self.table_name = 'md_ac_case_info'
end
