# frozen_string_literal: true

class USPatentsApplicant < ActiveRecord::Base
  # self.inheritance_column = :some_other
  establish_connection(Storage.use(host: :db01, db: :usa_raw))
end

