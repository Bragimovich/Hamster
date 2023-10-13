# frozen_string_literal: true

class AmericanExpressFounds2019 < ActiveRecord::Base
  # self.inheritance_column = :some_other
  self.table_name = 'american_express_founds_2019'
  establish_connection(Storage.use(host: :db01, db: :woke_project))
end


