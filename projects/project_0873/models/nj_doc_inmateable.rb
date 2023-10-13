# frozen_string_literal: true

module NjDocInmateable
  extend ActiveSupport::Concern

  included do
    self.inheritance_column = :_type_disabled
    self.establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.logger = Logger.new(STDOUT)
  end

  class_methods do
    def update_history!(run_id)
      deleted_records = where.not(touched_run_id: run_id)
      deleted_records.update_all(deleted: true)
    end
  end
end
