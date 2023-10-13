DROP TEMPORARY table index_tmp_2;
CREATE TEMPORARY table index_tmp SELECT MAX(id) as id, data_source_url, count(*) as `count` FROM Illinois  GROUP BY data_source_url ORDER BY `count` DESC;
CREATE TEMPORARY table index_tmp_2 SELECT MIN(id) as id, data_source_url, count(*) as `count` FROM Illinois WHERE deleted = 0  GROUP BY data_source_url HAVING count > 1 ORDER BY `count` DESC;
UPDATE Illinois SET deleted = 0 WHERE id IN (SELECT id FROM index_tmp_2);
UPDATE Illinois SET deleted = 1 WHERE id IN (SELECT id FROM index_tmp_2);
DROP TEMPORARY table index_tmp_2;
DROP TEMPORARY table index_tmp;

SELECT count(*) FROM Illinois WHERE deleted = 0;
