# frozen_string_literal: true

require_relative '../models/ga_raw_models'
MAIN_TABLE = 'il_chicago_arrests__csv'

class  Keeper < Hamster::Harvester
  def initialize
    super
  end

  def safe_operation(model, retries=10)
    begin
      yield(model) if block_given?
    rescue *CONNECTION_ERROR_CLASSES => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.warn(e.class)
        logger.warn("#{STARS}Reconnect!#{STARS}")
        sleep 100
        Hamster.report(to: OLEKSII_KUTS, message: "project-#{Hamster::project_number} Keeper: Reconnecting...")
        model.connection.reconnect!
      rescue *CONNECTION_ERROR_CLASSES => e
        retry
      end
    retry
    end
  end

  def filer_ids
    safe_operation(GARawContributions) { |model| model.distinct.pluck(:filer_id) }
  end

  def store(csv_folder)
    run = Runs.create
    @run_id = run.id
    store_candidates("#{csv_folder}candidate.csv")
    store_committees("#{csv_folder}committee.csv")
    run.status = 'finish'
  rescue SQLException => e
    logger.error(e)
    run.status = 'error'
  ensure
    run.save
  end

  def store_candidates(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'GA_RAW_CANDIDATES'
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16)
        SET
        filer_id                = NULLIF(@p1, ''),
        candidate_full_name     = NULLIF(@p2, ''),
        candidate_address1      = NULLIF(@p3, ''),
        candidate_address2      = NULLIF(@p4, ''),
        candidate_csz           = NULLIF(@p5, ''),
        candidate_phone1        = NULLIF(@p6, ''),
        candidate_phone2        = NULLIF(@p7, ''),
        candidate_party         = NULLIF(@p8, ''),
        candidate_office_sought = NULLIF(@p9, ''),
        committee_name          = NULLIF(@p10, ''),
        committee_address1      = NULLIF(@p11, ''),
        committee_address2      = NULLIF(@p12, ''),
        committee_csz           = NULLIF(@p13, ''),
        committee_phone1        = NULLIF(@p14, ''),
        committee_phone2        = NULLIF(@p15, ''),
        data_source_url         = NULLIF(@p16, ''),
        run_id                  = #{@run_id},
        touched_run_id          = #{@run_id},
        md5_hash                = MD5(CONCAT_WS('', @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15));

    UPDATE `#{main_table}`
       SET deleted = 1
     WHERE filer_id
        IN (SELECT filer_id
              FROM `#{main_table}__csv`);

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;

    UPDATE `#{main_table}` SET deleted = 1
    WHERE touched_run_id <> #{@run_id}
    AND deleted = 0;
    SQL

    run_queries(sql_text)
  end

  def store_committees(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'GA_RAW_COMMITTEES'
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12)
        SET
        filer_id                  = NULLIF(@p1, ''),
        committee_name            = NULLIF(@p2, ''),
        committee_address1        = NULLIF(@p3, ''),
        committee_address2        = NULLIF(@p4, ''),
        committee_csz             = NULLIF(@p5, ''),
        committee_phone1          = NULLIF(@p6, ''),
        committee_phone2          = NULLIF(@p7, ''),
        committee_affiliation     = NULLIF(@p8, ''),
        committee_type            = NULLIF(@p9, ''),
        committee_recall_office   = NULLIF(@p10, ''),
        committee_recall_officer  = NULLIF(@p11, ''),
        data_source_url           = NULLIF(@p12, ''),
        run_id                    = #{@run_id},
        touched_run_id            = #{@run_id},
        md5_hash                  = MD5(CONCAT_WS('', @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11));

    UPDATE `#{main_table}`
       SET deleted = 1
     WHERE filer_id
        IN (SELECT filer_id
              FROM `#{main_table}__csv`);

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;

    UPDATE `#{main_table}` SET deleted = 1
    WHERE touched_run_id <> #{@run_id}
    AND deleted = 0;
    SQL

    run_queries(sql_text)
  end

  def run_queries(sql_text)
    queries = sql_text.split(';')
    queries.each do |query|
      query.strip!
      run_sql(query.strip + ';') unless query.empty?
    end
  end

  def run_sql(sql_text)
    logger.info("#{STARS}\n#{Time.now}#{STARS}\n#{sql_text}")
    GARawContributions.connection.execute(sql_text)
  end
end
