CREATE TABLE `tributearchive_settings`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `obituary_id`                   BIGINT(20),
  `show_store`                    BOOLEAN,
  `show_tribute_fund`             BOOLEAN,
  `tribute_fund_expired`          BOOLEAN,
  `crowdfunding_external_link`    BOOLEAN,
  `show_store_for_past_event`     BOOLEAN,
  `store_url`                     VARCHAR(255),
  `use_custom_store_url`          BOOLEAN,
  `disable_tree_product`          BOOLEAN,
  `privatize_guest_book`          BOOLEAN,
  `top_banner_url`                VARCHAR(255),
  `is_plant_tree_active`          BOOLEAN,
  `tree_store_link`               VARCHAR(255),
  `hide_tribute_wall`             BOOLEAN,
  `link_to_obituary_wall`         BOOLEAN,
  `has_pending_posts`             BOOLEAN,
  `hide_read_more_button`         BOOLEAN,
  `round_obituary_photos`         BOOLEAN,
  `is_dvd_purchase_enabled`       BOOLEAN,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255)      NOT NULL,
  UNIQUE KEY `obituary` (`obituary_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Aleksa Gegic';