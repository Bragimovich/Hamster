# frozen_string_literal: true

module RawTributearchiveable
  extend ActiveSupport::Concern

  included do
    self.inheritance_column = :_type_disabled
    self.establish_connection(Storage[host: :db01, db: :obituary])
  end

  class_methods do
    def c__and__u!(run_id, hash_data)
      record = find_by(obituary_id: hash_data[:obituary_id])
      if record.nil?
        hash_data.merge!(run_id: run_id, touched_run_id: run_id)
        create!(hash_data)
      elsif record.md5_hash != hash_data[:md5_hash]
        hash_data.merge!(touched_run_id: run_id, deleted: false)
        record.update!(hash_data)
      else
        record.update!(touched_run_id: run_id, deleted: false)
      end
    end

    def update_history!(run_id)
      deleted_records = where.not(touched_run_id: run_id)
      deleted_records.update_all(deleted: true)
    end
  end
end
