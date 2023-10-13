# frozen_string_literal: true

module MeScCaseable
  extend ActiveSupport::Concern

  included do
    self.inheritance_column = :_type_disabled
    self.establish_connection(Storage[host: :db01, db: :us_court_cases])
  end

  class_methods do
    def store_info_hash(run_id, hash)
      case_date = Date.parse(hash[:case_filed_date]) rescue nil
      record = find_by(case_id: hash[:case_id], deleted: false)

      if record.nil?
        hash.merge!(run_id: run_id, touched_run_id: run_id)
        create!(hash)
      elsif record.md5_hash != hash[:md5_hash]
        case_date_db = Date.parse(record.case_filed_date) rescue nil

        if (case_date && case_date_db) && (case_date > case_date_db)
          hash.merge!(touched_run_id: run_id, deleted: false)
          record.update!(hash)
        else
          record.update!(touched_run_id: run_id, deleted: false)
        end
      else
        record.update!(touched_run_id: run_id, deleted: false)
      end
    end

    def store_data(run_id, data)
      array_hashes = data.is_a?(Array) ? data : [data]

      array_hashes.each do |hash|
        record = if name.match? /Activities/
                    find_by(
                      case_id:       hash[:case_id],
                      activity_date: hash[:activity_date],
                      activity_desc: hash[:activity_desc],
                      activity_type: hash[:activity_type],
                      file:          hash[:file]
                    )
                  elsif name.match? /Party/
                    find_by(
                      case_id:            hash[:case_id],
                      is_lawyer:          hash[:is_lawyer],
                      party_name:         hash[:party_name],
                      party_type:         hash[:party_type],
                      party_law_firm:     hash[:party_law_firm]
                    )
                  else
                    find_by(md5_hash: hash[:md5_hash])
                  end
                  
        if record.nil?
          hash.merge!(run_id: run_id, touched_run_id: run_id)
          create!(hash)
        elsif record.md5_hash != hash[:md5_hash]
          hash.merge!(touched_run_id: run_id, deleted: false)
          record.update!(hash)
        else
          record.update!(touched_run_id: run_id, deleted: false)
        end
      end
    end

  end
end