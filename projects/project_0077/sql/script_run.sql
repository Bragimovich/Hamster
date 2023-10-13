SET @var_touched_run_id = '15';
SET @create_by = 'Mikhail Golovanov';
SET @data_source_url = 'https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2';

LOAD DATA LOCAL INFILE '/home/mike/HarvestStorehouse/project_0077/store/crimes_2001_to_present.csv'
    INTO TABLE `chicago_crime_statistics_load_csv`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@id_court, @case_number, @date1, @block, @iucr, @primary_type, @description, @location_desc, @arrest, @domestic,
     @beat, @distrinct, @ward, @community_area, @fbi_code, @x_coordinate, @y_coordinate, @year, @update_on, @latitude, @longitude, @location)
    SET date_court = STR_TO_DATE(@date1, '%m/%d/%Y %h:%i:%s %p'),
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
        update_on = STR_TO_DATE(@update_on, '%m/%d/%Y %h:%i:%s %p'),
        latitude = IF(@latitude = '', NULL, latitude),
        longitude = IF(@longitude = '', NULL, longitude),
        location = @location,
        md5_hash = MD5(REPLACE(CONCAT_WS('', @date1, @id_court,
                                         @case_number, @block, @iucr, @primary_type, @description, @location_desc, @arrest, @domestic,
                                         @beat, @distrinct, @ward, @community_area, @fbi_code, @x_coordinate, @y_coordinate, @year,
                                         @update_on, @latitude, @longitude, @location), ' ', ''));



CREATE TEMPORARY TABLE IF NOT EXISTS  `chicago_crime_statistics_tmp_list_court_id` AS
SELECT t2.id_court FROM `chicago_crime_statistics` AS t1, `chicago_crime_statistics_load_csv` AS t2
WHERE t1.deleted = 0 AND t1.md5_hash = t2.md5_hash;


CREATE TEMPORARY TABLE IF NOT EXISTS `chicago_crime_statistics_tmp_list_court_insert` AS
SELECT @var_touched_run_id as run_id,
       @data_source_url as data_source_url,
       @create_by as created_by,
       @var_touched_run_id as touched_run_id,
       0 as deleted,
       t2.*  FROM `chicago_crime_statistics_load_csv` AS t2,
                  `chicago_crime_statistics_tmp_list_court_id` AS t1
        WHERE t2.id_court <> t1.id_court;

# UPdate touched run id
UPDATE  `chicago_crime_statistics` AS t1, `chicago_crime_statistics_tmp_list_court_id` AS t2
SET t1.touched_run_id = @var_touched_run_id
WHERE t1.id_court = t2.id_court;

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
) SELECT * FROM `chicago_crime_statistics_tmp_list_court_insert`;


UPDATE `chicago_crime_statistics` SET deleted = 1
WHERE touched_run_id <> @var_touched_run_id
  AND deleted = 0;

TRUNCATE TABLE `chicago_crime_statistics_load_csv`;

DROP TEMPORARY TABLE IF EXISTS chicago_crime_statistics_tmp_list_court_id;
DROP TEMPORARY TABLE IF EXISTS chicago_crime_statistics_tmp_list_court_insert;