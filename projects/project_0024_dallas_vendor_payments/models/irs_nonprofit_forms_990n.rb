# frozen_string_literal: true

class IrsNonprofitForms990n < ActiveRecord::Base
  self.table_name = 'irs_nonprofit_forms_990n'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
