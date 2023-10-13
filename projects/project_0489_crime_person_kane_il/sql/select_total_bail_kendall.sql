SELECT 'Illinois', 'Kane',t.id, data_source_url, full_name, age, aws_link, arrest_date, booking_number,  t2.description,
       unpaid_bond_amount, unpaid_bail_amount, t1.summ_bonds, t3.facility, t4.court_name
FROM
    ( SELECT
          id, data_source_url, full_name, age, aws_link,
          arrest_date, booking_number,
          GROUP_CONCAT(unpaid_bond_amount) unpaid_bond_amount,
          GROUP_CONCAT(unpaid_bail_amount) unpaid_bail_amount
      FROM ( SELECT t0.id, t0.data_source_url, t0.full_name, t0.age, cmg.aws_link,
                    t2.arrest_date, t2.booking_number,
                    IF(t3.bond_category = 'Total Bond1', t3.bond_amount, NULL) as unpaid_bond_amount,
                    IF(t3.bond_category = 'Total Bail1', t3.bond_amount, NULL) as unpaid_bail_amount
#         chf.facility, cch.court_name
             FROM il_dupage__arrestees t0
                      LEFT JOIN il_dupage__mugshots cmg on cmg.arrestee_id = t0.id AND cmg.deleted = 0
                      LEFT JOIN il_dupage__arrests t2 ON t2.arrestee_id = t0.id AND t2.deleted = 0
                      LEFT JOIN il_dupage__bonds t3 on t3.arrest_id = t2.id AND t3.deleted = 0 ) t0
      GROUP BY id ) t
        LEFT JOIN
    ( SELECT
          id, summ_bonds
      FROM ( SELECT t0.id, IF ( t3.bond_category = 'Total Bond', SUM(REPLACE(REPLACE(bond_amount, '$', ''), ',', '')) , NULL) AS summ_bonds
#         chf.facility, cch.court_name
             FROM il_dupage__arrestees t0
                      LEFT JOIN il_dupage__mugshots cmg on cmg.arrestee_id = t0.id AND cmg.deleted = 0
                      LEFT JOIN il_dupage__arrests t2 ON t2.arrestee_id = t0.id AND t2.deleted = 0
                      LEFT JOIN il_dupage__bonds t3 on t3.arrest_id = t2.id AND t3.deleted = 0
             GROUP BY id HAVING summ_bonds IS NOT NULL) t0 ) t1 ON t1.id = t.id
        LEFT JOIN
    (SELECT
         id, description
     FROM ( SELECT t0.id, t3.description
#         chf.facility, cch.court_name
            FROM il_dupage__arrestees t0
                     LEFT JOIN il_dupage__mugshots cmg on cmg.arrestee_id = t0.id AND cmg.deleted = 0
                     LEFT JOIN il_dupage__arrests t2 ON t2.arrestee_id = t0.id AND t2.deleted = 0
                     LEFT JOIN il_dupage__charges t3 on t3.arrest_id = t2.id  AND t3.deleted = 0 ) t0 WHERE description IS NOT NULL GROUP BY description, id ) t2 ON t2.id = t.id
        LEFT JOIN
    ( SELECT
          id, facility
      FROM ( SELECT t0.id, t3.facility
             FROM il_dupage__arrestees t0
                      LEFT JOIN il_dupage__mugshots cmg on cmg.arrestee_id = t0.id
                      LEFT JOIN il_dupage__arrests t2 ON t2.arrestee_id = t0.id
                      LEFT JOIN il_dupage__holding_facilities t3 on t3.arrest_id = t2.id   ) t0 WHERE facility IS NOT NULL GROUP BY id, facility ) t3 ON t3.id = t.id
        LEFT JOIN
    ( SELECT
          id, court_name
      FROM ( SELECT t0.id, t3.court_name
             FROM il_dupage__arrestees t0
                      LEFT JOIN il_dupage__mugshots cmg on cmg.arrestee_id = t0.id
                      LEFT JOIN il_dupage__arrests t2 ON t2.arrestee_id = t0.id
                      LEFT JOIN il_dupage__charges t4 ON t4.arrest_id = t2.id
                      LEFT JOIN il_dupage__court_hearings t3 on t3.charge_id = t2.id   ) t0 WHERE court_name IS NOT NULL GROUP BY id, court_name ) t4 ON t4.id = t.id

WHERE summ_bonds is not null and summ_bonds!=0
GROUP BY t.id, t2.description;