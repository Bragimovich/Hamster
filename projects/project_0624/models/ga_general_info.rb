class GaGeneralInfo < ActiveRecord::Base
    include Hamster::Loggable

    establish_connection(Storage[host: :db01, db: :us_schools_raw])
    self.table_name = 'ga_general_info'
    self.inheritance_column = :_type_disabled

    def self.store_state(state_record, run_id)
        record_md5_hash = Digest::MD5.hexdigest(state_record.to_s)
        record = find_by(md5_hash: record_md5_hash)

        if record
            update(record['id'], {touched_run_id: run_id})
        else
            insert(state_record.merge({
                md5_hash: record_md5_hash,
                run_id: run_id,
                touched_run_id: run_id
            }))
        end
    end

    def self.store_district(district_record, run_id)
        record_md5_hash = Digest::MD5.hexdigest(district_record.to_s)
        record = find_by(md5_hash: record_md5_hash)

        if record
            update(record['id'], {touched_run_id: run_id})
        else
            insert(district_record.merge({
                md5_hash: record_md5_hash,
                run_id: run_id,
                touched_run_id: run_id
            }))
        end
    end

    def self.store_school(school_record, district_id, record_from_file , run_id)
        # If the record is from file instead of db, then we already have the
        # general_id of district is already in the school_record
        if !record_from_file    
            school_district = find_by(is_district: 1, number: district_id.to_i)
            school_record[:district_id] = school_district[:id]
        end

        record_md5_hash = Digest::MD5.hexdigest(school_record.to_s)
        record = find_by(md5_hash: record_md5_hash)
        if record
            update(record['id'], {touched_run_id: run_id})
        else
            insert(school_record.merge({
                md5_hash: record_md5_hash,
                run_id: run_id,
                touched_run_id: run_id
            }))
        end
    end

    def self.get_id(record)
        if record[:type] == "State"
            state = find_by(name: 'State')
            return state ? state[:id] : nil
        elsif record[:type] == "District"
            district = find_by(is_district: 1, number: record[:district_number].to_i)
            return district ? district[:id] : nil
        elsif record[:type] == "School"
            district = find_by(is_district: 1, number: record[:district_number].to_i)
            school = find_by(is_district: 0, district_id: district[:id], number: record[:school_number].to_i)
            
            return school ? school[:id] : nil
        else
            @logger.error "Bad Record Type!"
        end
    end
end
