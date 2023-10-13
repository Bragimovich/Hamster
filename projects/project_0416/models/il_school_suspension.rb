# frozen_string_literal: true

class IlSchoolSuspension < ActiveRecord::Base
  # self.inheritance_column = :some_other
  establish_connection(Storage.use(host: :db01, db: :il_raw))
end
