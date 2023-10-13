ALTER TABLE chicago_federation_musicians
    ADD COLUMN `year` INT(11) NOT NULL AFTER `data_source_url`;

UPDATE chicago_federation_musicians SET year = '2020'