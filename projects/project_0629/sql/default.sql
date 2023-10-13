{"collectionAlias"=>"p17027coll8",
 "index"=>nil,
 "itemId"=>"7859",
 "filetype"=>"pdf",
 "thumbnailUri"=>"/api/singleitem/collection/p17027coll8/id/7859/thumbnail",
 "thumbnailEnabled"=>true,
 "itemLink"=>"/singleitem/collection/p17027coll8/id/7859",
 "metadataFields"=>
  [{"field"=>"title", "value"=>"A145179, Petition - Reconsideration"},
   {"field"=>"subjec", "value"=>"Cruze v. Hudler"},
   {"field"=>"relispt", "value"=>"A145179"},
   {"field"=>"cdmcoll", "value"=>"Briefs -- Oregon Court of Appeals"}],
 "title"=>"A145179, Petition - Reconsideration"}


CREATE TABLE `or_saac_case_api_items`
(
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `collectionAlias`   VARCHAR(255),
  `index`             VARCHAR(255),
  `itemId`            INT(11),
  `filetype`          VARCHAR(255),
  `thumbnailUri`      VARCHAR(255),
  `thumbnailEnabled`  BOOLEAN,
  `itemLink`          VARCHAR(255),
  `metadataFields`    MEDIUMTEXT,
  `title`             VARCHAR(255),
  # any columns
  `data_source_url`   VARCHAR(255)      DEFAULT 'https://cdm17027.contentdm.oclc.org/digital/api/',
  `created_by`        VARCHAR(255)      DEFAULT 'Oleksij Kuc',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE `itemLink` (`itemLink`),
  INDEX `collection` (`collectionAlias`),
  INDEX `item_id` (`itemId`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'saac_api_items for `US Courts Expansion: Oregon Supreme and Appellate Courts (338 and 461) cases from cdm17027.contentdm.oclc.org`...., Created by Oleksij Kuc, Task #629';
