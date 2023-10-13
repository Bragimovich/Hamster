create TABLE ihsa_schools__sports_types(
    id BIGINT(20) auto_increment primary key,
    sport_name VARCHAR(255),
    UNIQUE(sport_name)
);