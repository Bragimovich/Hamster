# frozen_string_literal: true

class MsBarMsbarOrg < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'ms_bar_msbar_org'
  self.inheritance_column = :_type_disabled
end
