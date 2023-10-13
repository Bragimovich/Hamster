class GaEnrollmentByGrade < ActiveRecord::Base
    include Hamster::Loggable

    establish_connection(Storage[host: :db01, db: :us_schools_raw])
    self.table_name = 'ga_enrollment_by_grade'
    self.inheritance_column = :_type_disabled

    def self.store(record, run_id)
        record_md5_hash = Digest::MD5.hexdigest(record.to_s)
        record_in_db = find_by(md5_hash: record_md5_hash)

        if record_in_db
            update(record_in_db['id'], {touched_run_id: @run_id})
        else
            insert(record.merge({
                md5_hash: record_md5_hash,
                run_id: run_id,
                touched_run_id: run_id
            }))
        end
    end
end
