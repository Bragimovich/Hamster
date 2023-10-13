# frozen_string_literal: true

module OhSchoolaable
  extend ActiveSupport::Concern

  included do
    self.inheritance_column = :_type_disabled
    self.establish_connection(Storage[host: :db01, db: :us_schools_raw])
  end

  class_methods do
    def update_history!(run_id)
      deleted_records = where.not(touched_run_id: run_id)
      deleted_records.update_all(deleted: true)
      touched_records = where(touched_run_id: run_id)
      touched_records.update_all(deleted: false)
    end
  end
end
