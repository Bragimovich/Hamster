module TablesGenerator
  
  def generate_tables_if_not_exist(court)
    @client = Mysql2::Client.new(Storage[host: :db01, db: :us_court_cases].except(:adapter).merge(symbolize_keys: true))

    court_abbr = court.court_abbr
    author = court.author
    
    courts_table_name = "#{court_abbr}_courts"
    create_courts_table(courts_table_name, court) unless is_table_exist(courts_table_name)

    case_party_table_name = "#{court_abbr}_case_party"
    create_case_party_table(case_party_table_name, author) unless is_table_exist(case_party_table_name)

    case_info_table_name = "#{court_abbr}_case_info"
    create_case_info_table(case_info_table_name, author) unless is_table_exist(case_info_table_name)

    case_activities_table_name = "#{court_abbr}_case_activities"
    create_case_activities_table(case_activities_table_name , author) unless is_table_exist(case_activities_table_name )

    runs_table_name = "#{court_abbr}_runs"
    create_runs_table(runs_table_name , court) unless is_table_exist(runs_table_name )

    @client.close
  end
  
  def is_table_exist(table_name)
    tables_count    = @client.query("SELECT count(*) FROM information_schema.TABLES WHERE 
                      (TABLE_SCHEMA = 'us_court_cases') AND (TABLE_NAME = '#{table_name}')")

    tables_count.to_a.first[:"count(*)"] != 0
  end
  
  def create_courts_table(table_name, court)
    author = court.author
    query = <<~SQL
              CREATE TABLE #{table_name} (
                  id              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
                  run_id          BIGINT(20),
                  court_id        VARCHAR(255),
                  court_name      VARCHAR(255)       DEFAULT 'District Court for the Southern District of Ohio',
                  court_state     VARCHAR(255)       DEFAULT 'OH',
                  court_type      VARCHAR(255)       DEFAULT 'Federal',
                  court_sub_type  VARCHAR(255)       DEFAULT 'District',
                  data_source_url TEXT,
                  created_by      VARCHAR(255)       DEFAULT '#{author}',
                  created_at      DATETIME           DEFAULT CURRENT_TIMESTAMP,
                  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  touched_run_id  BIGINT,
                  deleted         BOOLEAN            DEFAULT 0,
                  md5_hash        VARCHAR(255),
                  INDEX run_id (run_id),
                  INDEX touched_run_id (touched_run_id),
                  INDEX deleted (deleted),
                  INDEX md5_hash (md5_hash)
              ) DEFAULT CHARSET = utf8mb4
                COLLATE = utf8mb4_unicode_520_ci;
          SQL
      @client.query(query)

    save_init_court(court, table_name)
  end

  def create_case_party_table(table_name, author)
    query = <<~SQL
              CREATE TABLE #{table_name} (
                id                     BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
                run_id                 BIGINT(20),
                court_id               VARCHAR(255) NOT NULL,
                case_id                VARCHAR(255) NOT NULL,
                party_name             VARCHAR(255) NOT NULL,
                party_type             VARCHAR(255) NOT NULL,
                party_address          VARCHAR(255) NOT NULL,
                party_city             VARCHAR(255) NOT NULL,
                party_state            VARCHAR(255) NOT NULL,
                party_zip              VARCHAR(255) NOT NULL,
                law_firm               VARCHAR(255) NOT NULL,
                lawyer_additional_data TEXT NOT NULL,
                party_description       TEXT,
                is_lawyer              BOOLEAN NOT NULL,
                data_source_url        TEXT,
                scrape_frequency       VARCHAR(255)       DEFAULT 'daily',
                created_by             VARCHAR(255)       DEFAULT '#{author}',
                created_at             DATETIME           DEFAULT CURRENT_TIMESTAMP,
                updated_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                touched_run_id         BIGINT,
                deleted                BOOLEAN            DEFAULT 0,
                md5_hash               VARCHAR(255),
                INDEX run_id (run_id),
                INDEX touched_run_id (touched_run_id),
                INDEX deleted (deleted),
                INDEX md5_hash (md5_hash)
              ) DEFAULT CHARSET = utf8mb4
                COLLATE = utf8mb4_unicode_520_ci;
    SQL
    @client.query(query)
  end

  def create_case_info_table(table_name, author)
    query = <<~SQL
              CREATE TABLE #{table_name} (
                id                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
                run_id                BIGINT(20),
                court_id              VARCHAR(255),
                case_name             VARCHAR(255),
                case_id               VARCHAR(255),
                case_filed_date       VARCHAR(255),
                case_description      TEXT,
                case_type             VARCHAR(255),
                disposition_or_status VARCHAR(255),
                status_as_of_date     VARCHAR(255),
                judge_name            VARCHAR(255),
                data_source_url       TEXT,
                scrape_frequency      VARCHAR(255)       DEFAULT 'daily',
                created_by            VARCHAR(255)       DEFAULT '#{author}',
                created_at            DATETIME           DEFAULT CURRENT_TIMESTAMP,
                updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                touched_run_id        BIGINT,
                deleted               BOOLEAN            DEFAULT 0,
                md5_hash              VARCHAR(255),
                INDEX run_id (run_id),
                INDEX touched_run_id (touched_run_id),
                INDEX deleted (deleted),
                INDEX md5_hash (md5_hash)
              ) DEFAULT CHARSET = utf8mb4
                COLLATE = utf8mb4_unicode_520_ci;
    SQL
    @client.query(query)
  end

  def create_case_activities_table(table_name, author)
    query = <<~SQL
              CREATE TABLE #{table_name} (
                id               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
                run_id           BIGINT(20),
                court_id         VARCHAR(255),
                case_id          VARCHAR(255),
                activity_date    VARCHAR(255),
                activity_decs    TEXT,
                activity_pdf     VARCHAR(255),
                data_source_url  TEXT,
                scrape_frequency VARCHAR(255)       DEFAULT 'daily',
                created_by       VARCHAR(255)       DEFAULT '#{author}',
                created_at       DATETIME           DEFAULT CURRENT_TIMESTAMP,
                updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                touched_run_id   BIGINT,
                deleted          BOOLEAN            DEFAULT 0,
                md5_hash         VARCHAR(255),
                INDEX run_id (run_id),
                INDEX touched_run_id (touched_run_id),
                INDEX deleted (deleted),
                INDEX md5_hash (md5_hash)
              ) DEFAULT CHARSET = utf8mb4
                COLLATE = utf8mb4_unicode_520_ci;
    SQL
    @client.query(query)
  end

  def create_runs_table(table_name, court)
    author = court.author
    query = <<~SQL
              CREATE TABLE #{table_name} (
                id               BIGINT AUTO_INCREMENT PRIMARY KEY,
                status           VARCHAR(255)       DEFAULT 'processing',
                downloading_status VARCHAR(255)       DEFAULT 'processing',
                storing_status     VARCHAR(255)       DEFAULT 'waiting',
                created_by       VARCHAR(255)       DEFAULT '#{author}',
                created_at       DATETIME           DEFAULT CURRENT_TIMESTAMP,
                updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX status_idx (status)
              ) DEFAULT CHARSET = utf8mb4
                COLLATE = utf8mb4_unicode_520_ci;
    SQL
    @client.query(query)
  end

  def save_init_court(court, table_name)
    run_id = 1
    court_id = court.court_id
    court_name = court.court_name
    court_state = court.court_state
    court_type = court.court_type
    court_sub_type = court.court_sub_type
    md5 = HashConvertor.new.court_to_md5(court_name, court_state, court_type, court_sub_type)
    data_source_url = "https://pacer.login.uscourts.gov/csologin/login.jsf"
    touched_run_id = 1
    md5_hash = md5

    query = <<~SQL
              INSERT INTO #{table_name} (run_id, court_id, court_name, court_state, court_type, court_sub_type, data_source_url,
              touched_run_id, md5_hash) values (#{run_id}, #{court_id}, '#{court_name}', '#{court_state}', '#{court_type}', 
             '#{court_sub_type}', '#{data_source_url}', #{touched_run_id}, '#{md5_hash}')
    SQL
    @client.query(query)
  end
end