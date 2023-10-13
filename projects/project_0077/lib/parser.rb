# frozen_string_literal: true

require_relative '../models/general'
require_relative '../models/general_tmp'
require_relative '../models/runs'
##https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2

class Parser < Hamster::Parser

  FILENAME = "crimes_2001_to_present.csv"
  URL = "https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2"
  CREATED_BY = "Mikhail Golovanov"
  TABLE = "chicago_crime_statistics"
  TMP_TABLE = "chicago_crime_statistics_tmp"

  def initialize args
    super
    if args[:debug]
      @debug = true
    end
    @run_id = (args[:run_id].nil?) ? 0 : args[:run_id]
  end

  def parse
    res = Runs.find(@run_id)
    res.status = 'finish'
    temp_csv_src = storehouse + "store/" + FILENAME

    sql_create = <<~SQL
      LOAD DATA LOCAL INFILE '%s'
          INTO TABLE `chicago_crime_statistics_load_csv`
          FIELDS TERMINATED BY ',' ENCLOSED BY '"'
          LINES TERMINATED BY '\n'
          IGNORE 1 LINES
          (@id_court, @case_number, @date1, @block, @iucr, @primary_type, @description, @location_desc, @arrest, @domestic,
           @beat, @distrinct, @ward, @community_area, @fbi_code, @x_coordinate, @y_coordinate, @year, @update_on, @latitude, @longitude, @location)
          SET date_court = STR_TO_DATE(@date1, '%%m/%%d/%%Y %%h:%%i:%%s %%p'),
              id_court = @id_court,
              case_number = @case_number,
              block = @block,
              iucr = @iucr,
              primary_type = @primary_type,
              description = @description,
              location_desc = @location_desc,
              arrest = CASE
                           WHEN @arrest = ''      THEN NULL
                           WHEN @arrest = 'false' THEN 0
                           WHEN @arrest = 'true'  THEN 1
                  END,
              domestic = CASE
                             WHEN @domestic = '' THEN NULL
                             WHEN @domestic = 'false' THEN 0
                             WHEN @domestic = 'true' THEN 1
                  END,
              beat = IF(@beat = '', NULL , @beat),
              distrinct = IF(@distrinct = '', NULL , @distrinct),
              ward = IF(@ward = '', NULL, @ward),
              community_area = IF(@community_area = '', NULL, @community_area),
              fbi_code = @fbi_code,
              x_coordinate = IF(@x_coordinate = '', NULL, @x_coordinate),
              y_coordinate = IF(@y_coordinate = '', NULL, @y_coordinate),
              year = @year,
              update_on = STR_TO_DATE(@update_on, '%%m/%%d/%%Y %%h:%%i:%%s %%p'),
              latitude = IF(@latitude = '', NULL, latitude),
              longitude = IF(@longitude = '', NULL, longitude),
              location = @location,
              md5_hash = MD5(REPLACE(CONCAT_WS('', @date1, @id_court,
                                               @case_number, @block, @iucr, @primary_type, @description, @location_desc, @arrest, @domestic,
                                               @beat, @distrinct, @ward, @community_area, @fbi_code, @x_coordinate, @y_coordinate, @year,
                                               @update_on, @latitude, @longitude, @location), ' ', ''));


      INSERT INTO `chicago_crime_statistics` (
          `run_id`,
          `data_source_url`,
          `created_by`,
          `touched_run_id`,
          `deleted`,
          `id_court`,
          `case_number`,
          `date_court`,
          `block`,
          `iucr`,
          `primary_type`,
          `description`,
          `location_desc`,
          `arrest`,
          `domestic`,
          `beat`,
          `distrinct`,
          `ward`,
          `community_area`,
          `fbi_code`,
          `x_coordinate`,
          `y_coordinate`,
          `year`,
          `update_on`,
          `latitude`,
          `longitude`,
          `location`,
          `md5_hash`
      ) SELECT 
             '%d' AS run_id,
             '%s' AS data_source_url,
             '%s' AS created_by,
             '%d' AS touched_run_id,
             0 AS deleted,
             t2.* FROM `chicago_crime_statistics_load_csv` AS t2
             ON DUPLICATE KEY UPDATE touched_run_id = '%d', deleted = 0;


      UPDATE `chicago_crime_statistics` SET deleted = 1
            WHERE touched_run_id <> '%d'
              AND deleted = 0;

      TRUNCATE TABLE `chicago_crime_statistics_load_csv`;
    SQL

    sql = sprintf(sql_create, temp_csv_src, @run_id, URL, CREATED_BY, @run_id, @run_id, @run_id)

    begin

      queries = sql.split(';')
      queries.each do |query|
        query.strip!
        GeneralTmp.connection.execute(query) unless query.empty?
      end

    rescue SQLException => e
      res.status = "error"
    ensure
      res.save()
    end
  end
end
