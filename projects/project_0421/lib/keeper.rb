# frozen_string_literal: true

require_relative '../models/runs'
require_relative '../models/district_columbia__dcd_uscourts_gov'

class Keeper < Hamster::Harvester
  def initialize
    super
  end

  def update_run_id(run_id)
    sql_text = <<~SQL
      UPDATE `district_columbia__dcd_uscourts_gov` SET deleted = 1
      WHERE touched_run_id <> #{run_id}
      AND deleted = 0;
    SQL
    Runs.connection.execute(sql_text)
  end

  def get_sql(csv_src, run_id)
    sql_text = ""
    sql_text = <<~SQL
    SET @run_id = #{run_id};

    CREATE TEMPORARY TABLE `district_columbia__dcd_uscourts_gov__csv` LIKE `district_columbia__dcd_uscourts_gov`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `district_columbia__dcd_uscourts_gov__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17)
        SET run_id = @run_id,
            name = @p1,
            first_name          = @p2,
            middle_name         = NULLIF(@p3 , ''),
            last_name           = NULLIF(@p4 , ''),
            law_firm_name       = NULLIF(@p5 , ''),
            law_firm_address    = NULLIF(@p6 , ''),
            law_firm_city       = NULLIF(@p7 , ''),
            law_firm_state      = NULLIF(@p8 , ''),
            law_firm_zip        = NULLIF(@p9 , ''),
            email               = NULLIF(@p10 , ''),
            phone               = NULLIF(@p11 , ''),
            fax                 = NULLIF(@p12 , ''),
            registration_status = NULLIF(@p13 , ''),
            bar_number          = NULLIF(@p14 , ''),
            date_admited        = NULLIF(@p15 , ''),
            data_source_url     = @p16,
            touched_run_id      = @run_id,
            md5_hash            = @p17;

    ALTER TABLE `district_columbia__dcd_uscourts_gov__csv` DROP COLUMN id;

    INSERT INTO `district_columbia__dcd_uscourts_gov`
    SELECT null, t2.* FROM `district_columbia__dcd_uscourts_gov__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0, data_source_url = t2.data_source_url;

    DROP TEMPORARY TABLE `district_columbia__dcd_uscourts_gov__csv`;
    SQL
    sql_text
  end

  def run_sql(sql_text)
    logger.info("#{STARS}\n#{Time.now}#{STARS}\n#{sql_text}")
    Runs.connection.execute(sql_text)
  end

  def store_members(csv_src, run_id)
    sql = get_sql(csv_src, run_id)
    queries = sql.split(';')
    queries.each do |query|
      query.strip!
      run_sql(query + ';') unless query.empty?
    end
  end

  def store(csv_src)
    run = Runs.create
    @run_id = run.id
    store_members(csv_src, @run_id)
    update_run_id(@run_id)
    run.status = 'finish'
  rescue SQLException => e
    logger.error(e)
    run.status = 'error'
  ensure
    run.save
  end
end
