# frozen_string_literal: true

require_relative '../models/runs'
MAIN_TABLE = 'il_professional_licenses__csv'

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
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29, @p30, @p31)
        SET run_id                                  = @run_id,
            license_type                            = @p2,
            description                             = @p3,
            license_number                          = @p4,
            status                                  = @p5,
            business                                = (@p6 = 'Y'),
            title                                   = NULLIF(@p7, ''),
            first_name                              = NULLIF(@p8, ''),
            middle_name                             = NULLIF(@p9, ''),
            last_name                               = NULLIF(@p10, ''),
            prefix                                  = NULLIF(@p11, ''),
            suffix                                  = NULLIF(@p12, ''),
            busines_name                            = NULLIF(@p13, ''),
            busines_dba                             = NULLIF(@p14, ''),
            original_date                           = STR_TO_DATE(@p15, '%m/%d/%Y'),
            effective_date                          = STR_TO_DATE(NULLIF(@p16, ''), '%m/%d/%Y'),
            expiration_date                         = STR_TO_DATE(NULLIF(@p17, ''), '%m/%d/%Y'),
            city                                    = NULLIF(@p18, ''),
            state                                   = NULLIF(@p19, ''),
            zip                                     = NULLIF(@p20, ''),
            county                                  = NULLIF(@p21, ''),
            speciality                              = NULLIF(@p22, ''),
            controlled_substance_schedule           = NULLIF(@p23, ''),
            delegated_controlled_substance_schedule = NULLIF(@p24, ''),
            ever_disciplined                        = (@p25 = 'Y'),
            last_modified_date                      = STR_TO_DATE(@p26, '%m/%d/%Y'),
            discipline_case_number                  = NULLIF(@p27, ''),
            discipline_action                       = NULLIF(@p28, ''),
            discipline_start_date                   = STR_TO_DATE(NULLIF(@p29, ''), '%m/%d/%Y'),
            discipline_end_date                     = STR_TO_DATE(NULLIF(@p30, ''), '%m/%d/%Y'),
            discipline_reason                       = NULLIF(@p31, ''),
            data_source_url                         = @data_source_url,
            touched_run_id                          = @run_id,
            md5_hash                                = MD5(CONCAT_WS('', @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29, @p30, @p31)),
            md5_person                              = MD5(CONCAT_WS('', @p13, @p18, @p19, @p20, @p14)),
            md5_number                              = MD5(CONCAT_WS('', @p4, @p3, @p5, @p15, @p16, @p17)),
            md5_disciplinary                        = MD5(CONCAT_WS('', @p27, @p4, @p28, @p29, @p30, @p31));

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

    queries = get_sql(csv_src, URL).split(";\n")
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
