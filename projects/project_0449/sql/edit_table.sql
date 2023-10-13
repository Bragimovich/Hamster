
#     ADD CONSTRAINT `md5_hash_unique` UNIQUE (`md5_hash`);
#     ADD COLUMN touched_run_id VARCHAR(15) AFTER courts_of_admittance,
#     ADD COLUMN deleted tinyint(1) default 0 null AFTER touched_run_id,
#     ADD COLUMN md5_hash varchar(255) AFTER deleted,
#     ADD INDEX `md5_hash` (`md5_hash`),
#     ADD INDEX `touched_run_id` (`touched_run_id`),
#     ADD INDEX `first_name` (`first_name`),
#     ADD INDEX `last_name` (`last_name`),
#     ADD INDEX `law_firm_city` (`law_firm_city`),
#     ADD INDEX `law_firm_state` (`law_firm_state`),
#     ADD INDEX `name` (`name`)
# ;
use lawyer_status;
ALTER TABLE ms_mississippi_bar
#MODIFY COLUMN date_admited date;
ADD COLUMN `law_firm_address1` VARCHAR(255) AFTER law_firm_address,
ADD COLUMN `law_firm_address2` VARCHAR(255) AFTER law_firm_address1;

