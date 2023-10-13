# frozen_string_literal: true

class NyNewyorkBar < ActiveRecord::Base
  self.table_name = 'ny_newyork_bar'
	establish_connection(Storage[host: :db01, db: :lawyer_status])
end
  



