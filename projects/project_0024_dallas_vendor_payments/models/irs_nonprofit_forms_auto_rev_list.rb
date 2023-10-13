# frozen_string_literal: true

class IrsNonprofitFormsAutoRevList < ActiveRecord::Base
  self.table_name = 'irs_nonprofit_forms_auto_rev_list'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
