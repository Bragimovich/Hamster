# frozen_string_literal: true

module CaOcscCaseable
  extend ActiveSupport::Concern

  included do
    self.inheritance_column = :_type_disabled
    self.establish_connection(Storage[host: :db01, db: :us_court_cases])
  end

  class_methods do
    def c__and__u!(run_id, hash_data)
      if hash_data.is_a? Hash
        create_and_update!(run_id, hash_data)
      elsif hash_data.is_a? Array
        create_and_update_array!(run_id, hash_data)
      end
    end

    def update_history!(run_id)
      deleted_records = where.not(touched_run_id: run_id)
      deleted_records.update_all(deleted: true)
    end

    def create_and_update!(run_id, hash_data)
      record = find_by(case_id: hash_data[:case_id])
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

    def create_and_update_array!(run_id, hash_array)
      hash_array.uniq.each do |hash_data|
        record =
          if name.include?('CaOcscCaseActivity')
            find_by(
              case_id: hash_data[:case_id],
              activity_date: hash_data[:activity_date],
              activity_decs: hash_data[:activity_decs],
              data_source_url: hash_data[:data_source_url]
            )
          elsif name.include?('CaOcscCaseParty')
            find_by(
              case_id: hash_data[:case_id],
              is_lawyer: hash_data[:is_lawyer],
              party_name: hash_data[:party_name],
              party_type: hash_data[:party_type],
              party_description: hash_data[:party_description],
              data_source_url: hash_data[:data_source_url]
            )
          end

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
    end
  end
end
