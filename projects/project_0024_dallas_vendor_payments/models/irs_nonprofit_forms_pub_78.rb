# frozen_string_literal: true

class IrsNonprofitFormsPub78 < ActiveRecord::Base
  self.table_name = 'irs_nonprofit_forms_pub_78'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
