UPDATE chicago_crime_statistics_full SET x_coordinate = 0 WHERE x_coordinate = '';
UPDATE chicago_crime_statistics_full SET y_coordinate = 0 WHERE y_coordinate = '';
UPDATE chicago_crime_statistics_full SET latitude = 0 WHERE  latitude = '';
UPDATE chicago_crime_statistics_full SET longitude = 0 WHERE  longitude = '';
UPDATE chicago_crime_statistics_full SET arrest = 0 WHERE  arrest = 'false';
UPDATE chicago_crime_statistics_full SET arrest = 1 WHERE  arrest = 'true';
UPDATE chicago_crime_statistics_full SET domestic = 0 WHERE  domestic = 'false';
UPDATE chicago_crime_statistics_full SET domestic = 1 WHERE  domestic = 'true';
UPDATE chicago_crime_statistics_full SET ward = 0 WHERE  ward = '';
UPDATE chicago_crime_statistics_full SET community_area = 0 WHERE  community_area = '';
UPDATE chicago_crime_statistics_full SET distrinct = NULL WHERE distrinct = '';
UPDATE chicago_crime_statistics_full SET arrest = NULL WHERE arrest = '';



alter table chicago_crime_statistics_tmp
    modify block varchar(100),
    modify iucr varchar(6),
    modify case_number varchar(50),
    modify beat int,
    modify distrinct int,
    modify ward int,
    modify community_area int,
    modify arrest boolean,
    modify domestic boolean,
    modify primary_type varchar(60),
    modify description varchar(100),
    modify location_desc varchar(100),
    modify fbi_code varchar(10),
    modify x_coordinate int,
    modify y_coordinate int,
    modify latitude double,
    modify longitude double,
    modify location varchar(50);

CREATE INDEX chicago_crime_statistics_tmp_list_court_insert_id_court_index ON chicago_crime_statistics_tmp_list_court_insert (id_court);
CREATE INDEX chicago_crime_statistics_tmp_list_court_id_id_court_index ON chicago_crime_statistics_tmp_list_court_id (id_court);
CREATE INDEX chicago_crime_statistics_tmp_id_court_index ON chicago_crime_statistics_tmp (id_court);


SET @var_touched_run_id = 17;
SET @create_by = 'Mikhail Golovanov';
SET @data_source_url = 'https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2';



CREATE TABLE IF NOT EXISTS `chicago_crime_statistics_tmp`
(  `id_court` BIGINT,
   `case_number` varchar(50),
   `date_court`  datetime,
   `block` varchar(100),
   `iucr` varchar(6),
   `primary_type` varchar(60),
   `description` varchar(100),
   `location_desc` varchar(100),
   `arrest` boolean,
   `domestic` boolean,
   `beat` int,
   `distrinct` int,
   `ward` int,
   `community_area` int,
   `fbi_code` VARCHAR(10),
   `x_coordinate` int,
   `y_coordinate` int,
   `year` YEAR,
   `update_on` DATETIME,
   `latitude` double,
   `longitude` double,
   `location` varchar(50),
   `md5_hash` varchar(255)
);


SET @var_touched_run_id = 37;
SET @create_by = 'Mikhail Golovanov';
SET @data_source_url = '';

LOAD DATA LOCAL INFILE '/home/mike/HarvestStorehouse/project_0077/store/crimes_2001_to_present.csv'
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


DROP TABLE IF EXISTS chicago_crime_statistics_tmp_list_court_id;
DROP TABLE IF EXISTS chicago_crime_statistics_tmp_list_court_insert;

CREATE TEMPORARY TABLE IF NOT EXISTS  `chicago_crime_statistics_tmp_list_court_id` AS
SELECT t2.id_court FROM `chicago_crime_statistics` AS t1, `chicago_crime_statistics_load_csv` AS t2
WHERE t1.deleted = 0 AND t1.md5_hash = t2.md5_hash;


CREATE TEMPORARY TABLE IF NOT EXISTS `chicago_crime_statistics_tmp_list_court_insert` AS
SELECT @var_touched_run_id as run_id,
       @data_source_url as data_source_url,
       @create_by as created_by,
       @var_touched_run_id as touched_run_id,
       0 as deleted,
       t2.*  FROM `chicago_crime_statistics_load_csv` AS t2
WHERE id_court not in ( SELECT id_court FROM `chicago_crime_statistics_tmp_list_court_id` );

# UPdate touched run id
UPDATE  `chicago_crime_statistics` AS t1, `chicago_crime_statistics_tmp_list_court_id` AS t2
SET t1.touched_run_id = @var_touched_run_id
WHERE t1.id_court = t2.id_court;

INSERT IGNORE INTO `chicago_crime_statistics` (
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

TRUNCATE chicago_crime_statistics_load_csv;



CREATE TEMPORARY TABLE IF NOT EXISTS `chicago_crime_statistics_tmp_list_court_insert` AS
    SELECT @var_touched_run_id AS run_id,
            @data_source_url AS data_source_url,
            @create_by AS created_by,
            @var_touched_run_id AS touched_run_id,
            0 AS deleted,
            t2.*  FROM `chicago_crime_statistics_load_csv` AS t2,
                       `chicago_crime_statistics_tmp_list_court_id` AS t1
            WHERE t2.id_court <> t1.id_court;
