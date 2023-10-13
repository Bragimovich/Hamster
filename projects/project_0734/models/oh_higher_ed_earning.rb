class OhHigherEdEarning < ActiveRecord::Base
    include Hamster::Loggable

    establish_connection(Storage[host: :db01, db: :state_salaries__raw])
    self.table_name = 'oh_higher_ed_earnings'
    self.inheritance_column = :_type_disabled


    def self.store(record_hash, run_id)
        record_md5_hash = Digest::MD5.hexdigest(record_hash.to_s)
        record = find_by(md5_hash: record_md5_hash)

        if record
            update(record['id'], {touched_run_id: run_id})
        else
            insert(record_hash.merge({
                md5_hash: record_md5_hash,
                run_id: run_id,
                touched_run_id: run_id
            }))
        end
    end
end
