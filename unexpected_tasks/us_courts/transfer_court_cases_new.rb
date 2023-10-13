
require_relative 'transfer_cases/us_cases'
require_relative 'transfer_cases/transfer_run_id'


module UnexpectedTasks
  module UsCourts
    class TransferCourtCasesNew
      def self.run(**options)
        TransferStartccnew.new(**options)
      end
    end

    class TransferStartccnew
      def initialize(**options)
        @client = connect_to_db(database=:us_court_cases)
        start
      end

      def start
        @run_id_models = {
          info: TransferRunId.new(:info),
          party: TransferRunId.new(:party),
          activities: TransferRunId.new(:activities),
          judgment: TransferRunId.new(:judgment),
          pdfs_on_aws: TransferRunId.new(:pdfs_on_aws),
        }

        query = "SELECT court_id, court_name_id, court_name, created_by FROM us_courts_start WHERE not_test=1"
        statement = @client.prepare(query)
        result = statement.execute
        result.each do |court|
          Hamster.logger.info "Start transfer #{court[:court_name]} (#{court[:court_id]}) ..."
          next if last_update(court[:court_id])
          errors = 0
          queries = insert_query_to_db(court)
          tables = check_nonexistent_tables(court[:court_name_id], make_table_names(court[:court_name_id]))
          tables.each do |type, table_name|
            Hamster.logger.info type
            begin
              Hamster.logger.info "INSERT"
              db_run(queries[type])
              next if [:relations_info_pdf, :relations_activity_pdf].include?(type)
              Hamster.logger.info "DELETE"
              db_run(delete_query(type, court))
              Hamster.logger.info "UPDATE"
              db_run(update_run_id_query(type, court))
            rescue => e
              Hamster.logger.error("ERROR: #{e}")
              errors +=1
            end

            Hamster.logger.info "Check data"
            check_data(type, court) if ![:relations_info_pdf, :relations_activity_pdf].include?(type)
            Hamster.logger.info "END"
            @client = connect_to_db(database=:us_court_cases)
          end
          error_in_court(court[:court_id], errors)
        end
        db_run(update_uuid_query)
      end

      def tables_without_courts
        [:relations_info_pdf, :relations_activity_pdf]
      end

      private

      def connect_to_db(database=:us_court_cases)
        @client.close if !@client.nil?
        Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
      end

      def db_run(query)
        @client.query(query)
      end

      def insert_query_to_db(court)
        {
          info:
            "INSERT IGNORE INTO us_courts.us_case_info (court_id, case_id, case_name, case_filed_date, case_type, case_description, disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by, md5_hash, run_id, touched_run_id)
                SELECT court_id, case_id, case_name, case_filed_date, case_type,case_description,  disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by, md5_hash, #{@run_id_models[:info].run_id}, #{@run_id_models[:info].run_id}
                FROM us_court_cases.#{court[:court_name_id]}_case_info WHERE deleted=0 and court_id=#{court[:court_id]};",
          party:
            "INSERT IGNORE INTO us_courts.us_case_party (court_id, case_id, is_lawyer, party_name, party_type, party_law_firm, party_address, party_city, party_state, party_zip, party_description, data_source_url, created_by,  md5_hash, run_id, touched_run_id)
                SELECT court_id, case_id, is_lawyer, party_name, party_type, law_firm, party_address, party_city, party_state, party_zip, party_description, data_source_url, created_by, md5_hash, #{@run_id_models[:party].run_id}, #{@run_id_models[:party].run_id}
                FROM us_court_cases.#{court[:court_name_id]}_case_party WHERE deleted=0 and court_id=#{court[:court_id]};",
          activities:
            "INSERT IGNORE INTO us_courts.us_case_activities (court_id, case_id, activity_date, activity_decs, activity_type, activity_pdf, data_source_url, created_by, md5_hash, run_id, touched_run_id, generated_uuid)
                SELECT court_id, case_id, activity_date, activity_decs, activity_type, activity_pdf, data_source_url, created_by, md5_hash, #{@run_id_models[:activities].run_id}, #{@run_id_models[:activities].run_id}, UUID()
                FROM us_court_cases.#{court[:court_name_id]}_case_activities WHERE deleted=0 and court_id=#{court[:court_id]};",
          judgment:
            "INSERT IGNORE INTO us_courts.us_case_judgment (court_id, case_id, complaint_id, party_name, fee_amount, requested_amount, case_type, judgment_amount, judgment_date, data_source_url, created_by, md5_hash, run_id, touched_run_id)
                SELECT court_id, case_id, complaint_id, party_name, fee_amount, requested_amount, case_type, judgment_amount, judgment_date, data_source_url, created_by, md5_hash, #{@run_id_models[:judgment].run_id}, #{@run_id_models[:judgment].run_id}
                FROM us_court_cases.#{court[:court_name_id]}_case_judgment where deleted=0 and court_id=#{court[:court_id]};",
          pdfs_on_aws:
            "INSERT IGNORE INTO us_courts.us_case_pdfs_on_aws (court_id, case_id, source_type, aws_link, source_link, created_by, md5_hash, run_id, touched_run_id)
                SELECT court_id, case_id, source_type, aws_link, source_link, created_by, md5_hash, #{@run_id_models[:pdfs_on_aws].run_id}, #{@run_id_models[:pdfs_on_aws].run_id}
                FROM us_court_cases.#{court[:court_name_id]}_case_pdfs_on_aws where deleted=0 and court_id=#{court[:court_id]};",
          relations_info_pdf:
            "INSERT IGNORE INTO us_courts.us_case_relations_info_pdf (case_info_md5, case_pdf_on_aws_md5, created_by)
                SELECT case_info_md5, case_pdf_on_aws_md5, created_by
                FROM us_court_cases.#{court[:court_name_id]}_case_relations_info_pdf;",
          relations_activity_pdf:
            "INSERT IGNORE INTO us_courts.us_case_relations_activity_pdf (case_activities_md5, case_pdf_on_aws_md5, created_by)
                SELECT case_activities_md5, case_pdf_on_aws_md5, created_by
                FROM us_court_cases.#{court[:court_name_id]}_case_relations_activity_pdf;",
        }
      end

      def delete_query(type, court)
        additional =
          if [:info, :party, :activities, :judgment].include?(type)
             "AND additional_or_old=0"
          else
            ""
          end

        "UPDATE us_courts.us_case_#{type} t1
            LEFT JOIN us_court_cases.#{court[:court_name_id]}_case_#{type} t2 on t1.md5_hash = t2.md5_hash and t2.deleted = 0
            SET t1.deleted=1
            WHERE t1.court_id = #{court[:court_id]} #{additional} and t2.id is null"

      end

      def update_run_id_query(type, court)
        "UPDATE us_courts.us_case_#{type} t1
            LEFT JOIN us_court_cases.#{court[:court_name_id]}_case_#{type} t2 on t1.md5_hash = t2.md5_hash and t2.deleted = 0
            SET t1.deleted=0, t1.touched_run_id = #{@run_id_models[type].run_id}
            WHERE t1.court_id = #{court[:court_id]} and t2.id is not null"
      end

      def make_table_names(court_name)
        {
          #:court => "#{court_name}_courts",
          :info => "#{court_name}_case_info",
          #:lawyer => "#{court_name}_case_lawyer",
          :party => "#{court_name}_case_party",
          :activities => "#{court_name}_case_activities",
          :complaint => "#{court_name}_case_complaint",
          :judgment => "#{court_name}_case_judgment",
          :pdfs_on_aws => "#{court_name}_case_pdfs_on_aws",
          :relations_info_pdf => "#{court_name}_case_relations_info_pdf",
          :relations_activity_pdf => "#{court_name}_case_relations_activity_pdf"
        }
      end

      def check_nonexistent_tables(court_name, table_names_hash)
        court_tables_in_db = existed_court_table(court_name)
        table_names_hash.each do |table_key, table_name|
          next if table_name.in?(court_tables_in_db)
          table_names_hash.delete(table_key)
        end
        table_names_hash
      end

      def existed_court_table(court_name)
        query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'us_court_cases' AND table_name like '#{court_name}_%'; "
        statement = @client.prepare(query)
        result = statement.execute
        result.map { |row| row[:table_name] }
      end

      def check_data(type, court)
        check_query = "SELECT count(*) skipped_rows from us_court_cases.#{court[:court_name_id]}_case_#{type}
          where md5_hash not in (SELECT md5_hash from us_courts.us_case_#{type} where court_id=#{court[:court_id]} and deleted=0)
        and court_id=#{court[:court_id]} and deleted=0"
        skipped_rows =
          begin
            db_run(check_query).first[:skipped_rows]
          rescue
            -1
          end

        analysis_court_row = TransferCasesTableAnalysis.where(court_id:court[:court_id]).first
        if analysis_court_row.nil?
          TransferCasesTableAnalysis.insert({
                                              court_id:court[:court_id],
                                              court_name_id:court[:court_name_id],
                                              court_name:court[:court_name],
                                              created_by: court[:created_by],
                                              saac:0,
                                            })
          analysis_court_row = TransferCasesTableAnalysis.where(court_id:court[:court_id]).first
        end
        updated_analysis_court_row = {type.to_s => skipped_rows, :last_type => type}

        if type==:info
          # Put last created_at time
          last_created_query = "SELECT max(created_at) ca
                                FROM us_court_cases.#{court[:court_name_id]}_case_#{type}
                              WHERE court_id=#{court[:court_id]} and deleted=0"

          updated_analysis_court_row[:last_created] = db_run(last_created_query).first[:ca]
        end
        analysis_court_row.update(updated_analysis_court_row)
      end

      def last_update(court_id, day=1)
        TransferCasesTableAnalysis.where(court_id:court_id).where("updated_at>CurDate()-1").first
      end

      def error_in_court(court_id, errors)
        TransferCasesTableAnalysis.where(court_id:court_id).update(errors_in_court:errors)
      end

      def update_uuid_query
        "UPDATE us_courts.us_case_info i
          JOIN us_courts_staging.courts courts on i.court_id = courts.external_id
          JOIN us_courts_staging.cases c on i.case_id = c.raw_id and c.court_id = courts.id
        SET i.generated_uuid = c.generated_uuid
        WHERE i.generated_uuid is null;"
      end
    end



  end
end

