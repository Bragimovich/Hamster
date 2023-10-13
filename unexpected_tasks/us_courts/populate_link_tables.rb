module UnexpectedTasks
  module UsCourts
    #hamster do us_courts/populate_link_tables --debug
    #bundle exec ruby hamster.rb --do=us_courts/populate_link_tables
    # --table=judges_universities
    class PopulateLinkTables
      SLACK_ID = 'Eldar Eminov'.freeze
      TASK_NUM = 604
      DATASET  = 'us_courts_staging'.freeze
      PHASES   = ['', '_saac'].freeze
      TABLES_  = %w[judges_universities lawyers_universities judges_law_schools lawyers_law_schools
                    lawyers_law_firm_names judges_law_firm_names law_firm_names_addresses
                    cases_judges cases_lawyers non_lawyer_parties_non_lawyer_party_roles cases_non_lawyers].freeze

      def self.run(**options)
        @clear = options[:clear]
        @table = options[:table]
        @all   = true unless @table

        return send_log("Invalid value #{@table}! example: #{TABLES_}", :red) if @table && !TABLES_.include?(@table)

        @db = Mysql2::Client.new(Storage[host: 'db01', db: DATASET] .except(:adapter).merge(symbolize_keys: true))
        main
      rescue StandardError => e
        send_log("#{e} | #{e.full_message}", :red)
        Hamster.report(to: SLACK_ID, message: "#{TASK_NUM} | #{e}", use: :both)
      ensure
        @db&.close
      end

      private

      def self.count_rows(finish = false)
        query = "SELECT COUNT(*) FROM #{@table};"
        rows  = @db.query(query).to_a[0].values[0]
        report_message "Table: #{@table} | #{rows} rows | #{finish ? 'Finish' : 'Starting'}"
      end

      def self.report_message(message, color=:green)
        send_log(message, color)
        Hamster.report(to: SLACK_ID, message: "#{TASK_NUM} | #{message}", use: :both)
      end

      def self.send_log(message, color=:green)
        [:debug, :info].each { |method_| Hamster.logger.send(method_, message.send(color)) }
      end

      def report_attention
        5.times do |i|
          report_message('Attention! All link tables will be deleted!') if i == 0
          send_log(message, :red)
          sleep(1)
        end
      end

      def self.main
        report_attention if @clear
        tables = @table ? [@table] : TABLES_
        tables.each { |table| truncate_populate_table(table) }
        report_message "All tables #{@clear ? 'truncated and ' : ''}populated!\n#{TABLES_}" if @all
      end

      def self.truncate_populate_table(table=nil)
        @table = table if table
        count_rows
        self.truncate_table if @clear
        self.populate_table
        count_rows(true)
      end

      def self.populate_table(try=1)
        name = "fill_#{@table}".to_sym
        self.send(name)
      rescue Mysql2::Error::TimeoutError => error
        try += 1
        return report_message("The #{@table} table is not populated", :red) if try > 5

        report_message("#{error} | try is #{try}", :red)
        sleep 50*try
        retry
      end

      def self.truncate_table
        send_log("Starting truncate #{@table}")
        query = "TRUNCATE #{@table};"
        @db.query(query)
        send_log("Success truncated #{@table}")
      end

      def self.fill_cases_judges
        PHASES.each do |phase|
          query = <<~SQL
            INSERT IGNORE INTO #{@table}
            (case_id, judge_id, created_by)
            SELECT
              cases.id,
              judges_staging.id,
              'Eldar Eminov'
            FROM us_courts_staging.cases AS cases
            JOIN us_courts.us#{phase}_case_info AS info
              ON cases.external_id = info.id
            JOIN us_courts.us#{phase}_judges AS judges
              ON judges.judge_name = info.judge_name AND judges.court_id = info.court_id
            JOIN us_courts.us#{phase}_judges_clean clean
              ON clean.judge_id = judges.id
            JOIN us_courts.us#{phase}_judges_mbo AS mbo
              ON mbo.id = clean.judge_id_mbo
            JOIN us_courts_staging.judges AS judges_staging
              ON judges_staging.external_id = mbo.id
            WHERE cases.external_table = 'us#{phase}_case_info'
              AND info.deleted = 0
              AND clean.skip_it = 0
              AND judges_staging.external_table = 'us#{phase}_judges_mbo';
          SQL
          send_log("Starting for phase #{phase}")
          @db.query(query)
        end
      end

      def self.fill_cases_lawyers
        PHASES.each do |phase|
          query = <<~SQL
            INSERT IGNORE INTO #{@table}
            (case_id, lawyer_id, lawyer_type, created_by)
            SELECT
              cases.id           AS case_id,
              lawyers_staging.id AS lawyers_id,
              party.party_type   AS lawyer_type,
              'Eldar Eminov'     AS created_by
            FROM us_courts_staging.cases AS cases
            JOIN us_courts.us#{phase}_case_info AS info
              ON cases.external_id = info.id
            JOIN us_courts.us#{phase}_case_party AS party
              ON party.case_id = info.case_id AND party.court_id = info.court_id
            JOIN us_courts.us#{phase}_case_party_lawyers_cleaned AS clean
              ON clean.raw_id = party.id
            JOIN us_courts.us#{phase}_case_party_lawyers_unique AS uniq
              ON uniq.id = clean.lawyer_id
            JOIN us_courts_staging.lawyers AS lawyers_staging
              ON lawyers_staging.external_id = uniq.id
            WHERE cases.external_table = 'us#{phase}_case_info'
              AND info.deleted = 0
              AND party.is_lawyer = 1
              AND party.deleted = 0
              AND lawyers_staging.external_table = 'us#{phase}_case_party_lawyers_unique';
          SQL
          send_log("Starting for phase #{phase}")
          @db.query(query)
        end
      end

      def self.fill_cases_non_lawyers
        PHASES.each do |phase|
          query = <<~SQL
            INSERT IGNORE INTO #{@table}
              (case_id, non_lawyer_id, non_lawyer_type, created_by)
            SELECT
              cases.id,
              non.id,
              roles.role,
              'Eldar Eminov'
            FROM us_courts_staging.cases AS cases
            JOIN us_courts.us#{phase}_case_info AS info
              ON cases.external_id = info.id
            JOIN us_courts.us#{phase}_case_party party
              ON info.case_id = party.case_id AND info.court_id = party.court_id
            JOIN us_courts.us#{phase}_case_party_not_lawyers_cleaned AS cleaned
              ON cleaned.raw_id = party.id
            JOIN us_courts.us#{phase}_case_party_not_lawyers_unique AS uniq
              ON uniq.id = cleaned.party_id
            JOIN us_courts_staging.non_lawyer_parties AS non
              ON non.external_id = uniq.id
            JOIN us_courts.non_lawyer_party_type_normalization AS norm
              ON norm.party_type = party.party_type AND norm.court_id = party.court_id
            JOIN us_courts_staging.non_lawyer_party_roles AS roles
              ON norm.similar_to = roles.external_id
            WHERE cases.external_table = 'us#{phase}_case_info'
              AND info.deleted = 0
              AND party.deleted = 0
              AND party.is_lawyer = 0;
          SQL
          send_log("Starting for phase #{phase}")
          @db.query(query)
        end
      end

      def self.fill_judges_universities
        [1,2].each do |university|
          query = <<~SQL
            INSERT IGNORE #{@table}
            (judge_id, university_id, start_year, end_year, created_by)
            SELECT
              jud.id                        AS judge_id,
              univer.id                     AS university_id,
              mbo.u#{university}_start_year AS start_year,
              mbo.u#{university}_end_year   AS end_year,
              'Eldar Eminov'                AS created_by
            FROM us_courts_staging.judges AS jud
            JOIN us_courts.us_judges_mbo AS mbo
              ON jud.external_id = mbo.id
            JOIN us_courts.us_universities_MATCHED AS matched
              ON matched.raw_name = mbo.university#{university}
            JOIN us_courts_staging.universities AS univer
              ON univer.name = matched.name
              AND univer.city = matched.city AND univer.state = matched.state
            WHERE matched.deleted = 0;
          SQL

          send_log "Starting to populate from the university_#{university} column"
          @db.query(query)
        end
      end

      def self.fill_lawyers_universities
        [1,2].each do |university|
          query = <<~SQL
            INSERT IGNORE #{@table}
            (lawyer_id, university_id, start_year, end_year, created_by)
            SELECT
              law.id                        AS lawyer_id,
              univer.id                     AS university_id,
              mbo.u#{university}_start_year AS start_year,
              mbo.u#{university}_end_year   AS end_year,
              'Eldar Eminov'                AS created_by
            FROM us_courts_staging.lawyers AS law
            JOIN us_courts.us_case_party_lawyers_unique AS uniq
              ON law.external_id = uniq.id
            JOIN us_courts.us_case_laywers_mbo AS mbo
              ON uniq.id = mbo.similar_to
            JOIN us_courts.us_universities_MATCHED AS matched
              ON matched.raw_name = mbo.university#{university}
            JOIN us_courts_staging.universities AS univer
              ON univer.name = matched.name
              AND univer.city = matched.city AND univer.state = matched.state
            WHERE mbo.deleted = 0 AND matched.deleted = 0;
          SQL

          send_log "Starting to populate from the university_#{university} column"
          @db.query(query)
        end
      end

      def self.fill_judges_law_schools
        query = <<~SQL
          INSERT IGNORE #{@table}
            (judge_id, law_school_id, start_year, end_year, created_by)
          SELECT
            jud.id             AS judges_id,
            school.id          AS law_school_id,
            CASE
              WHEN mbo.law_start_year = 0 THEN NULL
              ELSE mbo.law_start_year
            END               AS start_year,
            CASE
              WHEN mbo.law_end_year = 0 THEN NULL
              ELSE mbo.law_end_year
            END               AS start_year,
            'Eldar Eminov'    AS created_by
          FROM us_courts_staging.judges jud
          JOIN us_courts.us_judges_mbo mbo
            ON mbo.id = jud.external_id
          JOIN us_courts_staging.law_schools school
            ON school.law_school_id = mbo.law_school_id;
        SQL
        @db.query(query)
      end

      def self.fill_lawyers_law_schools
        query = <<~SQL
          INSERT IGNORE #{@table}
            (lawyer_id, law_school_id, start_year, end_year, created_by)
          SELECT
            law.id             AS lawyer_id,
            school.id          AS law_school_id,
            CASE
              WHEN mbo.law_school_start_year = 0 THEN NULL
              ELSE mbo.law_school_start_year
            END                AS start_year,
            CASE
              WHEN mbo.law_school_end_year = 0 THEN NULL
              ELSE mbo.law_school_end_year
            END                AS start_year,
            'Eldar Eminov'     AS created_by
          FROM us_courts_staging.lawyers law
          JOIN us_courts.us_case_laywers_mbo mbo
            ON mbo.id = law.external_id
          JOIN us_courts_staging.law_schools school
            ON school.law_school_id = mbo.law_school_id;
        SQL
        @db.query(query)
      end

      def self.fill_lawyers_law_firm_names
        query = <<~SQL
          INSERT IGNORE #{@table}
          (lawyer_id, law_firm_names_id, created_by)
          SELECT
            law.id         AS lawyer_id,
            firms.id       AS law_firm_names_id,
            'Eldar Eminov' AS created_by
          FROM us_courts_staging.lawyers law
          JOIN us_courts.us_case_party_lawyers_unique uniq
            ON law.external_id = uniq.id
          JOIN us_courts.us_case_laywers_mbo mbo
            ON mbo.similar_to = uniq.id
          JOIN us_courts_staging.law_firm_names firms
            ON firms.name = mbo.law_firm_name_clean
          WHERE mbo.lawyer_name IS NOT NULL
            AND mbo.lawyer_name != '' AND law.external_table='us_case_party_lawyers_unique';
        SQL
        @db.query(query)
      end

      def self.fill_judges_law_firm_names
        query = <<~SQL
          INSERT IGNORE #{@table}
            (judge_id, law_firm_id, created_by, previous_law_firm, last_year)
          SELECT
             j.id,
             lf.id,
             'Eldar Eminov',
             jlf.previous_law_office1,
             jlf.last_year1
          FROM us_courts_staging.judges j
          JOIN us_courts.judge_from_staging_table_with_law_firms jlf
            ON j.id = jlf.judge_id_staging
          JOIN us_courts_staging.law_firm_names lf
            ON lf.name = jlf.previous_law_office1;
        SQL
        @db.query(query)
      end

      def self.fill_non_lawyer_parties_non_lawyer_party_roles
        query = <<~SQL
          INSERT IGNORE #{@table}
            (non_lawyer_id, non_lawyer_party_role_id, created_by)
          SELECT parties.id, roles.id, 'Eldar Eminov'
          FROM us_courts_staging.non_lawyer_parties AS parties
          JOIN us_courts.us_case_party_not_lawyers_unique ucpnlu
            ON parties.external_id = ucpnlu.id
          JOIN us_courts.us_case_party ucp
            ON ucpnlu.raw_id = ucp.id
          JOIN us_courts.non_lawyer_party_type_normalization nlptn
            ON nlptn.party_type = ucpnlu.party_type and nlptn.court_id = ucp.court_id
          JOIN us_courts_staging.non_lawyer_party_roles roles
            ON nlptn.similar_to = roles.external_id;
        SQL
        @db.query(query)
      end

      def self.fill_law_firm_names_addresses
        query = <<~SQL
          INSERT IGNORE #{@table}
          (law_firm_name_id, law_firm_address_id, created_by)
          SELECT lfn.id, lfa.id, 'Eldar Eminov'
          FROM us_courts.us_case_lawyers__law_firms_CLEAN AS lf_old
          JOIN us_courts_staging.law_firm_names lfn
            ON lfn.name = lf_old.law_firm_name
          JOIN us_courts_staging.law_firm_addresses lfa
            ON lfa.street_address=lf_old.street_address
          WHERE  lfa.street_address!=''
            AND (lf_old.similar_to IS NOT NULL
            OR lf_old.id in (select distinct similar_to
                from us_courts.us_case_lawyers__law_firms_CLEAN
                where similar_to is not null))
            AND lf_old.need_delete IS NULL;
        SQL
        @db.query(query)
      end
    end
  end
end
