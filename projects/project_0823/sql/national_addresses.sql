CREATE TABLE national_addresses (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  OID BIGINT,
  State CHAR(2),
  County VARCHAR(40),
  Inc_Muni VARCHAR(100),
  Uninc_Comm VARCHAR(100),
  Nbrhd_Comm VARCHAR(100),
  Post_Comm VARCHAR(40),
  Zip_Code CHAR(7),
  Plus_4 CHAR(7),
  Bulk_Zip CHAR(7),
  Bulk_Plus4 CHAR(7),
  StN_PreMod VARCHAR(15),
  StN_PreDir VARCHAR(50),
  StN_PreTyp VARCHAR(35),
  StN_PreSep VARCHAR(20),
  StreetName VARCHAR(60),
  StN_PosTyp VARCHAR(50),
  StN_PosDir VARCHAR(50),
  StN_PosMod VARCHAR(25),
  AddNum_Pre VARCHAR(15),
  Add_Number BIGINT,
  AddNum_Suf VARCHAR(15),
  LandmkPart VARCHAR(150),
  LandmkName VARCHAR(150),
  Building VARCHAR(75),
  Floor VARCHAR(75),
  Unit VARCHAR(75),
  Room VARCHAR(75),
  Addtl_Loc VARCHAR(225),
  Milepost VARCHAR(50),
  Longitude DOUBLE,
  Latitude DOUBLE,
  NatGrid_Coord VARCHAR(50),
  GUID VARCHAR(255),
  Addr_Type VARCHAR(50),
  Placement VARCHAR(25),
  Source VARCHAR(75),
  AddAuth VARCHAR(75),
  UniqWithin VARCHAR(75),
  LastUpdate DATE,
  Effective DATE,
  Expired DATE,
  data_source_url VARCHAR(255),
  created_by varchar(255) DEFAULT 'Hassan',
  created_at datetime DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  run_id bigint(20) DEFAULT NULL,
  touched_run_id bigint(20) DEFAULT NULL,
  deleted tinyint(1) DEFAULT '0',
  md5_hash varchar(150) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY `md5_hash` (md5_hash),
  KEY `run_id` (run_id),
  KEY `touched_run_id` (touched_run_id),
  KEY `deleted` (deleted)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
