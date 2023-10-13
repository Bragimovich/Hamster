# frozen_string_literal: true

require_relative '../models/us_courts_nc_model'
EMPTY_SQL_IN = '""'

class Keeper < Hamster::Harvester
  def initialize
    super
    @update_flag = false
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

  # need to implement safe_operation
  def get_pdf_md5_hash(case_id)
    res = safe_operation(NCCaseRelationsActivityPdf)  { |model| model.where(case_id:case_id).map { |row| row.case_activities_md5 } }
    res + safe_operation(NCCaseRelationsInfoPdf)      { |model| model.where(case_id:case_id).map { |row| row.case_info_md5 } }
  end

  # need to implement safe_operation
  def cases_in_db_links
    safe_operation(NCCaseInfo) { |model| model.all.map {|row| row.data_source_url} }
  end

  # need to implement safe_operation
  def all_cases_this_run(update_flag)
    safe_operation(NCCaseInfo) { |model|
      return EMPTY_SQL_IN unless update_flag
      run_id = model.order(updated_at: :asc).last.touched_run_id
      cases  = model.where(touched_run_id:run_id).map {|row| row.case_id}
      sql_in = cases.to_s[1..-2]
    }
  end

  # implement safe_operation in the future if it will be needed
  def store(csv_path, update_flag)
    run = NCCaseRuns.create
    @run_id = run.id

    store_case_info("#{csv_path}case_info.csv")
    @cases_list_for_sql = all_cases_this_run(update_flag)
    store_case_party("#{csv_path}case_party.csv")
    store_case_activities("#{csv_path}case_activities.csv")
    store_case_additional_info("#{csv_path}case_additional_info.csv")
    store_case_pdfs_on_aws("#{csv_path}case_pdfs_on_aws.csv")
    store_case_relations_info_pdf("#{csv_path}case_relations_info_pdf.csv")
    store_case_relations_activity_pdf("#{csv_path}case_relations_activity_pdf.csv")
  #   store_members(csv_src, @run_id)
  #   update_run_id(@run_id)
    run.status = 'finish'
  rescue SQLException => e
    logger.error(e.backtrace)
    run.status = 'error'
  ensure
    run.save
  end

  def store_case_info(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'nc_saac_case_info'
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        case_name             = NULLIF(@p3, ''),
        case_filed_date       = NULLIF(@p4, ''),
        case_type             = NULLIF(@p5, ''),
        case_description      = NULLIF(@p6, ''),
        disposition_or_status = NULLIF(@p7, ''),
        status_as_of_date     = NULLIF(@p8, ''),
        judge_name            = NULLIF(@p9, ''),
        lower_court_id        = NULLIF(@p10, ''),
        lower_case_id         = NULLIF(@p11, ''),
        data_source_url       = NULLIF(@p12, ''),
        md5_hash              = @p13,
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    UPDATE `#{main_table}`
       SET deleted = 1
     WHERE case_id
        IN (SELECT case_id
              FROM `#{main_table}__csv`);

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    run_queries(sql_text)
  end

  def store_case_party(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'nc_saac_case_party'
    sql_text = ""
    sql_text = <<~SQL
    UPDATE `#{main_table}` SET deleted=1 WHERE case_id IN (#{@cases_list_for_sql});

    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13)
        SET
        court_id              = NULLIF(@p10, ''),
        case_id               = NULLIF(@p11, ''),
        party_name            = NULLIF(@p1, ''),
        party_type            = NULLIF(@p2, ''),
        party_description     = NULLIF(@p3, ''),
        party_address         = NULLIF(@p4, ''),
        party_city            = NULLIF(@p5, ''),
        party_state           = NULLIF(@p6, ''),
        party_zip             = NULLIF(@p7, ''),
        party_law_firm        = NULLIF(@p8, ''),
        is_lawyer             = NULLIF(@p9, ''),
        data_source_url       = NULLIF(@p12, ''),
        md5_hash              = @p13,
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    run_queries(sql_text)
  end

  def store_case_activities(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'nc_saac_case_activities'
    sql_text = ""
    sql_text = <<~SQL
    UPDATE `#{main_table}` SET deleted=1 WHERE case_id IN (#{@cases_list_for_sql});

    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8)
        SET
        court_id              = NULLIF(@p5, ''),
        case_id               = NULLIF(@p6, ''),
        activity_type         = NULLIF(@p1, ''),
        activity_date         = NULLIF(@p2, ''),
        activity_desc         = NULLIF(@p3, ''),
        file                  = NULLIF(@p4, ''),
        data_source_url       = NULLIF(@p7, ''),
        md5_hash              = NULLIF(@p8, ''),
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    run_queries(sql_text)
  end

  def store_case_additional_info(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'nc_saac_case_additional_info'
    sql_text = ""
    sql_text = <<~SQL
    UPDATE `#{main_table}` SET deleted=1 WHERE case_id IN (#{@cases_list_for_sql});

    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10)
        SET
        court_id              = NULLIF(@p7, ''),
        case_id               = NULLIF(@p8, ''),
        lower_court_name      = NULLIF(@p1, ''),
        lower_case_id         = NULLIF(@p2, ''),
        lower_judge_name      = NULLIF(@p3, ''),
        lower_judgement_date  = NULLIF(@p4, ''),
        lower_link            = NULLIF(@p5, ''),
        disposition           = NULLIF(@p6, ''),
        data_source_url       = NULLIF(@p9, ''),
        md5_hash              = NULLIF(@p10, ''),
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    run_queries(sql_text)
  end

  def store_case_pdfs_on_aws(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'nc_saac_case_pdfs_on_aws'
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        source_type           = NULLIF(@p3, ''),
        aws_link              = NULLIF(@p4, ''),
        source_link           = NULLIF(@p5, ''),
        data_source_url       = NULLIF(@p6, ''),
        md5_hash              = NULLIF(@p7, ''),
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    run_queries(sql_text)
  end

  def store_case_relations_activity_pdf(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'nc_saac_case_relations_activity_pdf'
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        case_pdf_on_aws_md5   = NULLIF(@p3, ''),
        case_activities_md5   = NULLIF(@p4, '');

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    run_queries(sql_text)
  end

  def store_case_relations_info_pdf(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'nc_saac_case_relations_info_pdf'
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        case_pdf_on_aws_md5   = NULLIF(@p3, ''),
        case_info_md5         = NULLIF(@p4, '');

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
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
    NCCaseRuns.connection.execute(sql_text)
  end
end
