# frozen_string_literal: true

require_relative '../models/runs'
MAIN_TABLE = 'il_chicago_arrests__csv'

class  Keeper < Hamster::Harvester
  def initialize
    super
    @run_id = Runs.create.id
  end

  def get_sql(csv_src, source)
    sql_text = ""
    sql_text = <<~SQL
    SET @run_id = #{@run_id};
    SET @data_source_url = '#{source}';

    CREATE TEMPORARY TABLE `#{MAIN_TABLE}_temporary` LIKE `#{MAIN_TABLE}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{MAIN_TABLE}_temporary`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24)
        SET run_id                = @run_id,
            cb_no                 = @p1,
            case_number           = NULLIF(@p2, ''),
            arrest_date           = STR_TO_DATE(@p3, '%m/%d/%Y %h:%i:%s %p'),
            race                  = @p4,
            charge_1_statute      = @p5,
            charge_1_description  = @p6,
            charge_1_type         = NULLIF(@p7, ''),
            charge_1_class        = NULLIF(@p8, ''),
            charge_2_statute      = NULLIF(@p9, ''),
            charge_2_description  = NULLIF(@p10, ''),
            charge_2_type         = NULLIF(@p11, ''),
            charge_2_class        = NULLIF(@p12, ''),
            charge_3_statute      = NULLIF(@p13, ''),
            charge_3_description  = NULLIF(@p14, ''),
            charge_3_type         = NULLIF(@p15, ''),
            charge_3_class        = NULLIF(@p16, ''),
            charge_4_statute      = NULLIF(@p17, ''),
            charge_4_description  = NULLIF(@p18, ''),
            charge_4_type         = NULLIF(@p19, ''),
            charge_4_class        = NULLIF(@p20, ''),
            data_source_url       = @data_source_url,
            touched_run_id        = @run_id,
            md5_hash              = MD5(CONCAT_WS('', @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24));

    ALTER TABLE `#{MAIN_TABLE}_temporary` DROP COLUMN id;

    INSERT INTO `#{MAIN_TABLE}`
    SELECT null, t2.* FROM `#{MAIN_TABLE}_temporary` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{MAIN_TABLE}_temporary`;

    UPDATE `#{MAIN_TABLE}` SET deleted = 1
     WHERE touched_run_id <> #{@run_id}
       AND deleted = 0;
    SQL
    sql_text
  end

  def store_to_db(csv_src)
    res = Runs.find(@run_id)
    logger.info("#{STARS}\nStore '#{csv_src}' to DataBase")

    queries = get_sql(csv_src, LATEST).split(";\n")
    queries.each do |query|
      query.strip!
      run_sql(query + ';') unless query.empty?
    end

    res.status = 'finish'
    res.save
  end

  private

  def run_sql(sql_text)
    logger.info("#{STARS}\n#{Time.now}#{STARS}\n#{sql_text}")
    Runs.connection.execute(sql_text)
  end
end
