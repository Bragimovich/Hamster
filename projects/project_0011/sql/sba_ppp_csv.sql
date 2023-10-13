CREATE TABLE IF NOT EXISTS `usa_raw`.`sba_ppp_csv` (
`id` bigint(20) NOT NULL AUTO_INCREMENT,
`LoanNumber` bigint(20) DEFAULT NULL,
`DateApproved` date DEFAULT NULL,
`SBAOfficeCode` varchar(255) DEFAULT NULL,
`ProcessingMethod` varchar(255) DEFAULT NULL,
`BorrowerName` varchar(255) DEFAULT NULL,
`BorrowerAddress` varchar(255) DEFAULT NULL,
`BorrowerCity` varchar(255) DEFAULT NULL,
`BorrowerState` varchar(255) DEFAULT NULL,
`BorrowerZip` varchar(255) DEFAULT NULL,
`LoanStatusDate` date DEFAULT NULL,
`LoanStatus` varchar(255) DEFAULT NULL,
`Term` varchar(255) DEFAULT NULL,
`SBAGuarantyPercentage` decimal(10,2) DEFAULT NULL,
`InitialApprovalAmount` decimal(15,2) DEFAULT NULL,
`CurrentApprovalAmount` decimal(15,2) DEFAULT NULL,
`UndisbursedAmount` decimal(15,2) DEFAULT NULL,
`FranchiseName` varchar(255) DEFAULT NULL,
`ServicingLenderLocationID` varchar(255) DEFAULT NULL,
`ServicingLenderName` varchar(255) DEFAULT NULL,
`ServicingLenderAddress` varchar(255) DEFAULT NULL,
`ServicingLenderCity` varchar(255) DEFAULT NULL,
`ServicingLenderState` varchar(255) DEFAULT NULL,
`ServicingLenderZip` varchar(255) DEFAULT NULL,
`RuralUrbanIndicator` varchar(255) DEFAULT NULL,
`HubzoneIndicator` varchar(255) DEFAULT NULL,
`LMIIndicator` varchar(255) DEFAULT NULL,
`BusinessAgeDescription` varchar(255) DEFAULT NULL,
`ProjectCity` varchar(255) DEFAULT NULL,
`ProjectCountyName` varchar(255) DEFAULT NULL,
`ProjectState` varchar(255) DEFAULT NULL,
`ProjectZip` varchar(255) DEFAULT NULL,
`CD` varchar(255) DEFAULT NULL,
`JobsReported` varchar(255) DEFAULT NULL,
`NAICSCode` varchar(255) DEFAULT NULL,
`Race` varchar(255) DEFAULT NULL,
`Ethnicity` varchar(255) DEFAULT NULL,
`UTILITIES_PROCEED` decimal(15,2) DEFAULT NULL,
`PAYROLL_PROCEED` decimal(15,2) DEFAULT NULL,
`MORTGAGE_INTEREST_PROCEED` decimal(15,2) DEFAULT NULL,
`RENT_PROCEED` decimal(15,2) DEFAULT NULL,
`REFINANCE_EIDL_PROCEED` decimal(15,2) DEFAULT NULL,
`HEALTH_CARE_PROCEED` decimal(15,2) DEFAULT NULL,
`DEBT_INTEREST_PROCEED` decimal(15,2) DEFAULT NULL,
`BusinessType` varchar(255) DEFAULT NULL,
`OriginatingLenderLocationID` varchar(255) DEFAULT NULL,
`OriginatingLender` varchar(255) DEFAULT NULL,
`OriginatingLenderCity` varchar(255) DEFAULT NULL,
`OriginatingLenderState` varchar(255) DEFAULT NULL,
`Gender` varchar(255) DEFAULT NULL,
`Veteran` varchar(255) DEFAULT NULL,
`NonProfit` varchar(255) DEFAULT NULL,
`ForgivenessAmount` decimal(15,2) DEFAULT NULL,
`ForgivenessDate` date DEFAULT NULL,
`scrape_frequency` varchar(255) DEFAULT "Monthly",
`data_source_url` varchar(255) DEFAULT "https://data.sba.gov/dataset/ppp-foia",
`scrape_dev_name` varchar(255) DEFAULT 'Adeel',
`last_scrape_date` date DEFAULT NULL,
`next_scrape_date` date DEFAULT NULL,
`pl_gather_task_id` int(11) DEFAULT NULL,
`created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`file_name` varchar(100) DEFAULT NULL,
`run_id` int(11) DEFAULT NULL,
`BorrowerZip_5` char(5) GENERATED ALWAYS AS (left(`BorrowerZip`,5)) STORED,
`md5_hash` varchar(100) GENERATED ALWAYS AS (md5(concat_ws('',cast(`LoanNumber` as char),cast(`DateApproved` as char),`SBAOfficeCode`,`ProcessingMethod`,`BorrowerName`,`BorrowerAddress`,`BorrowerCity`,`BorrowerState`,`BorrowerZip`,cast(`LoanStatusDate` as char),`LoanStatus`,`Term`,cast(`SBAGuarantyPercentage` as char),cast(`InitialApprovalAmount` as char),cast(`CurrentApprovalAmount` as char),cast(`UndisbursedAmount` as char),`FranchiseName`,`ServicingLenderLocationID`,`ServicingLenderName`,`ServicingLenderAddress`,`ServicingLenderCity`,`ServicingLenderState`,`ServicingLenderZip`,`RuralUrbanIndicator`,`HubzoneIndicator`,`LMIIndicator`,`BusinessAgeDescription`,`ProjectCity`,`ProjectCountyName`,`ProjectState`,`ProjectZip`,`CD`,`JobsReported`,`NAICSCode`,`Race`,`Ethnicity`,cast(`UTILITIES_PROCEED` as char),cast(`PAYROLL_PROCEED` as char),cast(`MORTGAGE_INTEREST_PROCEED` as char),cast(`RENT_PROCEED` as char),cast(`REFINANCE_EIDL_PROCEED` as char),cast(`HEALTH_CARE_PROCEED` as char),cast(`DEBT_INTEREST_PROCEED` as char),`BusinessType`,`OriginatingLenderLocationID`,`OriginatingLender`,`OriginatingLenderCity`,`OriginatingLenderState`,`Gender`,`Veteran`,`NonProfit`,cast(`ForgivenessAmount` as char),cast(`ForgivenessDate` as char)))) STORED,
`deleted` int(11) DEFAULT '0',
`touched_run_id` int(11) DEFAULT NULL,
PRIMARY KEY (`id`),
UNIQUE INDEX `unique_records` (`md5_hash`),
INDEX `Borrower_state_city_idx` (`BorrowerState`,`BorrowerCity`),
INDEX `ServicingLenderName_idx` (`ServicingLenderName`),
INDEX `ServicingLender_state_city_idx` (`ServicingLenderState`,`ServicingLenderCity`),
INDEX `OriginatingLender_idx` (`OriginatingLender`),
INDEX `OriginatingLender_state_city_idx` (`OriginatingLenderState`,`OriginatingLenderCity`),
INDEX `BorrowerName_BusinessType_idx` (`BorrowerName`,`BusinessType`),
INDEX `DateApproved_name_city_state_idx` (`DateApproved`,`BorrowerName`,`BorrowerCity`,`BorrowerState`),
INDEX `run_id_index` (`run_id`),
INDEX `sba_ppp_csv_BorrowerAddress_index` (`BorrowerAddress`),
INDEX `BorrowerZip_index` (`BorrowerZip`),
INDEX `CurrentApprovalAmount_index` (`CurrentApprovalAmount`),
INDEX `BorrowerZip_5_index` (`BorrowerZip_5`),
INDEX `NAICSCode_idx` (`NAICSCode`),
INDEX `BusinessType_idx` (`BusinessType`),
INDEX `load_search` (`LoanNumber`),
INDEX `deleted_LoanNumber_idx` (`deleted`,`LoanNumber`),
INDEX `file_name_deleted_idx` (`file_name`,`deleted`),
INDEX `created_at_idx` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=35688472 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;
