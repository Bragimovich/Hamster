# frozen_string_literal: true

require_relative '../models/scbar_runs'

class Keeper < Hamster::Harvester
  def initialize
    super
  end

  def select(field, table, condition)
    sql_text = "SELECT #{field} from `#{table}` where #{condition}"
    Runs.connection.execute(sql_text).to_a
  end

  def fix_table
    sql_text = <<~SQL
      update `sc_bar_scbar_org` set last_name = concat(ucase(left(last_name, 1)),substring(last_name,2));
      update `sc_bar_scbar_org` set first_name = concat(ucase(left(first_name, 1)),substring(first_name,2));
      update `sc_bar_scbar_org` set middle_name = concat(ucase(left(middle_name, 1)),substring(middle_name,2));
      UPDATE `sc_bar_scbar_org` set first_name=(@temp:=first_name), first_name=middle_name, middle_name=@temp where length(first_name) =1 and length(middle_name) > 2;
      UPDATE `sc_bar_scbar_org` set first_name=(@temp:=first_name), first_name=middle_name, middle_name=@temp where length(first_name) = 2 and first_name like '%.' and length(middle_name) > 2 and not (length(middle_name) = 4 and middle_name like '%.')
    SQL
    sql_text
  end

  def update_run_id(run_id)
    sql_text = <<~SQL
      UPDATE `sc_bar_scbar_org` SET deleted = 1
      WHERE touched_run_id <> #{run_id}
      AND deleted = 0;
    SQL
    run_sql(sql_text)
  end

  def get_sql(csv_src, run_id)
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `sc_bar_scbar_org__csv` LIKE `sc_bar_scbar_org`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `sc_bar_scbar_org__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24)
        SET run_id              = #{run_id},
            bar_number          = @p1,
            name                = CASE
              WHEN @p2 = '' THEN null
              ELSE REPLACE(REPLACE(REPLACE(TRIM(@p2),' ','<>'),'><',''),'<>',' ')
            END,
            first_name          = NULLIF(@p3, ''),
            last_name           = NULLIF(@p4, ''),
            middle_name         = NULLIF(@p5, ''),
            date_admited        = NULLIF(@p6, ''),
            registration_status = NULLIF(@p7, ''),
            type                = NULLIF(@p8, ''),
            phone               = NULLIF(@p9, ''),
            email               = NULLIF(NULLIF(@p10, ''), '@'),
            fax                 = NULLIF(@p11, ''),
            law_firm_name       = NULLIF(@p12, ''),
            law_firm_address    = NULLIF(@p13, ''),
            law_firm_zip        = NULLIF(@p14, ''),
            law_firm_city       = NULLIF(@p15, ''),
            law_firm_state      = NULLIF(@p16, ''),
            law_firm_county     = NULLIF(NULLIF(@p17, ''), '\n'),
            university          = NULLIF(@p18, ''),
            website             = NULLIF(TRIM(@p19), ''),
            law_firm_website    = NULLIF(TRIM(@p19), ''),
            md5_hash            = @p20,
            data_source_url     = @p21,
            touched_run_id      = #{run_id};

    ALTER TABLE `sc_bar_scbar_org__csv` DROP COLUMN id;

    INSERT INTO `sc_bar_scbar_org`
    SELECT null, t2.* FROM `sc_bar_scbar_org__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{run_id}, deleted = 0;

    DROP TEMPORARY TABLE `sc_bar_scbar_org__csv`;
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
