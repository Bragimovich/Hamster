# frozen_string_literal: true

class MeScCasePdfsOnAws < ActiveRecord::Base
  include MeScCaseable

  self.table_name = 'me_sc_case_pdfs_on_aws'
end
