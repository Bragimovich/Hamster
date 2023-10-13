# frozen_string_literal: true

require_relative 'nj_doc_inmateable'
class NjDocInmateAdditionalInfo < ActiveRecord::Base
  include NjDocInmateable

  self.table_name = 'nj_doc_inmate_additional_info'
end
