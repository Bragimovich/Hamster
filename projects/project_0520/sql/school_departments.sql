create table ihsa_schools__departments(
  id BIGINT auto_increment PRIMARY KEY,
  division VARCHAR(255),
  UNIQUE(division)
);