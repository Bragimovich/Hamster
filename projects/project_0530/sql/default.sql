   
   ALTER TABLE usa_raw.us_weather_codes_pictures ADD UNIQUE(code_id, picture_id);
   
    CREATE TABLE `us_weather_forecast_daily` (
  `id` 							BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `city_id` 					BIGINT,
  `as_of_date` 					DATE,
  `date` 						DATE,
  `temperature_2m_max` 			VARCHAR(255),
  `temperature_2m_min` 			VARCHAR(255),
  `apparent_temperature_max` 	VARCHAR(255),
  `apparent_temperature_min` 	VARCHAR(255),
  `precipitation_sum` 			VARCHAR(255),
  `rain_sum` 					VARCHAR(255),
  `showers_sum` 				VARCHAR(255),
  `snowfall_sum` 				VARCHAR(255),
  `windspeed_10m_max` 			VARCHAR(255),
  `windgusts_10m_max` 			VARCHAR(255),
  `weathercode_id` 				INT,
  `sunrise` 					VARCHAR(255),
  `sunset` 						VARCHAR(255),
  `data_source_url` 			TEXT,
  `created_by`      			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mifeet__us_weather_1001`
    FOREIGN KEY (`city_id`)
    REFERENCES `usa_raw`.`us_cities_lat_lon` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_us_weather_forecast_daily_11`
    FOREIGN KEY (`weathercode_id`)
    REFERENCES `usa_raw`.`us_weather_code` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)	DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #530';
    
    CREATE TABLE `us_weather_historical_hourly` (
  `id` 							BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `city_id` 					BIGINT,
  `time` 						DATETIME,
  `temperature_2m` 				VARCHAR(255),
  `relativehumidity_2m` 		VARCHAR(255),
  `apparent_temperature` 		VARCHAR(255),
  `precipitation` 				VARCHAR(255),
  `rain` 						VARCHAR(255),
  `snowfall` 					VARCHAR(255),
  `cloudcover` 					VARCHAR(255),
  `data_source_url` 			TEXT,
  `created_by`      			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mifeet__us_weather_11`
    FOREIGN KEY (`city_id`)
    REFERENCES `usa_raw`.`us_cities_lat_lon` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)	DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #530';
    
    CREATE TABLE `us_weather_historical_daily` (
  `id` 							BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `city_id` 					BIGINT,
  `date` 						DATE,
  `temperature_2m_max` 			VARCHAR(255),
  `temperature_2m_min` 			VARCHAR(255),
  `precipitation_sum` 			VARCHAR(255),
  `rain_sum` 					VARCHAR(255),
  `snowfall_sum` 				VARCHAR(255),
  `windspeed_10m_max` 			VARCHAR(255),
  `windgusts_10m_max` 			VARCHAR(255),
  `sunrise` 					VARCHAR(255),
  `sunset` 						VARCHAR(255),
  `data_source_url` 			TEXT,
  `created_by`      			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mifeet__us_weather_10001`
    FOREIGN KEY (`city_id`)
    REFERENCES `usa_raw`.`us_cities_lat_lon` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)	DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #530';
    
    
    CREATE TABLE `us_cities_lat_lon` (
  `id` 							BIGINT(255) AUTO_INCREMENT PRIMARY KEY,
  `state` 						VARCHAR(255) NULL,
  `city` 						VARCHAR(255) NULL,
  `time_zone` 					VARCHAR(255) NULL,
  `pl_gis_lat` 					VARCHAR(255) NULL,
  `lp_gis_lon` 					VARCHAR(255) NULL,
  `open_meteo_lat` 				VARCHAR(255) NULL,
  `open_meteo_lon` 				VARCHAR(255) NULL,
  `created_by`      			VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      			DATETIME          DEFAULT CURRENT_TIMESTAMP,
)	DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #530';
    
       CREATE TABLE `us_cities_table` (
  `id` 					BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `state` 				VARCHAR(255),
  `city_nm` 			VARCHAR(255),
  `Urgent_city` 		VARCHAR(255),
  `total stores` 		VARCHAR(255),
  `created_by`      	VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      	TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  )  DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #530';
    
    
    CREATE TABLE `us_weather_code` (
  `id` 					INT PRIMARY KEY,
  `description` 		VARCHAR(255),
  `link_img` 			VARCHAR(255),
  `created_by`      	VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      	TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  ) DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #530';

CREATE TABLE `us_weather_codes_pictures` (
  `code_id` 				INT not null,
  `picture_id` 				INT not null,
   `created_by`      		VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
   `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `fk_us_weather_codes_pictures_1_idx` (`picture_id` ASC),
  CONSTRAINT `fk_us_weather_codes_pictures_1`
    FOREIGN KEY (`picture_id`)
    REFERENCES `usa_raw`.`us_weather_pictures` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_us_weather_codes_pictures_2`
    FOREIGN KEY (`code_id`)
    REFERENCES `usa_raw`.`us_weather_code` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)	DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #530';
    
    
    
    CREATE TABLE `us_weather_pictures` (
  `id` 						INT AUTO_INCREMENT PRIMARY KEY,
  `link` 					VARCHAR(255),
  `created_by`      		VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      		DATETIME          DEFAULT CURRENT_TIMESTAMP,
   `updated_at`      		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  )	DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #530';