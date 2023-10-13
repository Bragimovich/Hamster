def tc_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases;
  SQL
end

def tc_p1_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
    WHERE co.external_id < 300 OR co.external_id > 1099;
  SQL
end

def tc_p2_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
    WHERE co.external_id > 299 AND co.external_id < 1100;
  SQL
end

def tc_2020_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE filled_date >= '2020-01-01';
  SQL
end

def tc_2020_p1_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
    WHERE (co.external_id < 300 OR co.external_id > 1099)
      AND filled_date >= '2020-01-01';
  SQL
end

def tc_2020_p2_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
    WHERE co.external_id > 299 AND co.external_id < 1100
      AND filled_date >= '2020-01-01';
  SQL
end

def tc_wv_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
    WHERE co.state = 'WV';
  SQL
end

def tc_mo_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
    WHERE co.state = 'MO';
  SQL
end

def tc_la_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
    WHERE co.state = 'LA';
  SQL
end

def tc_f3m_query(today_3m)
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE filled_date >= '#{today_3m}';
  SQL
end

def tuc_2020_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE type IS NULL
      AND filled_date >= '2020-01-01';
  SQL
end

def tuc_2020_pdf_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE type IS NULL
      AND (id IN (SELECT DISTINCT case_id
                  FROM activities
                  WHERE pdf IS NOT NULL)
        OR summary_pdf IS NOT NULL)
      AND filled_date >= '2020-01-01';
  SQL
end

def tuc_2020_pdf_p1_query
  <<~SQL
    SELECT count(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
    WHERE ca.type IS NULL
      AND (ca.id IN (SELECT DISTINCT case_id
                     FROM activities
                     WHERE pdf IS NOT NULL)
        OR ca.summary_pdf IS NOT NULL)
      AND ca.filled_date >= '2020-01-01'
      AND (co.external_id < 300 OR co.external_id > 1099);
  SQL
end

def tuc_2020_pdf_p2_query
  <<~SQL
    SELECT count(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
    WHERE ca.type IS NULL
      AND (ca.id IN (SELECT DISTINCT case_id
                     FROM activities
                     WHERE pdf IS NOT NULL)
        OR ca.summary_pdf IS NOT NULL)
      AND ca.filled_date >= '2020-01-01'
      AND co.external_id > 299 AND co.external_id < 1100;
  SQL
end

def tuc_not_pdf_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE type IS NULL
      AND summary_pdf IS NULL
      AND id NOT IN (SELECT DISTINCT case_id
                     FROM activities
                     WHERE pdf IS NOT NULL);
  SQL
end

def tuc_not_pdf_rt_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE type IS NULL
      AND summary_pdf IS NULL
      AND id NOT IN (SELECT DISTINCT case_id
                     FROM activities
                     WHERE pdf IS NOT NULL)
      AND (description IS NOT NULL
        OR raw_type IS NOT NULL);
  SQL
end

def tuc_2020_not_pdf_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE type IS NULL
      AND summary_pdf IS NULL
      AND id NOT IN (SELECT DISTINCT case_id
                     FROM activities
                     WHERE pdf IS NOT NULL)
      AND filled_date >= '2020-01-01';
  SQL
end

def tuc_2020_not_pdf_rt_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE type IS NULL
      AND summary_pdf IS NULL
      AND id NOT IN (SELECT DISTINCT case_id
                     FROM activities
                     WHERE pdf IS NOT NULL)
      AND (description IS NOT NULL
        OR raw_type IS NOT NULL)
      AND filled_date >= '2020-01-01';
  SQL
end

def tuc_2020_as_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE type IS NULL
      AND court_id IN (SELECT id
                       FROM courts
                       WHERE sub_type = 'Court of Appeals'
                         OR sub_type = 'Supreme Court')
      AND filled_date >= '2020-01-01';
  SQL
end

def tuc_3m_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE type IS NULL
      AND (raw_type IS NOT NULL
        OR description IS NOT NULL
        OR summary_text IS NOT NULL
        OR complaint_text IS NOT NULL
        OR appeal_text IS NOT NULL
        OR id IN (SELECT DISTINCT case_id
                  FROM activities
                  WHERE pdf IS NOT NULL));
  SQL
end

def tuc_either_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases
    WHERE type IS NULL
      AND (raw_type IS NOT NULL
        OR description IS NOT NULL
        OR summary_text IS NOT NULL
        OR complaint_text IS NOT NULL
        OR appeal_text IS NOT NULL
        OR id IN (SELECT DISTINCT case_id
                  FROM activities
                  WHERE pdf IS NOT NULL))
      AND filled_date >= '2020-01-01';
  SQL
end

def tco_p2_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM courts
    WHERE external_id > 299
      AND external_id < 1100;
  SQL
end

def tco_p2_x_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM courts
    WHERE external_id > 299
      AND external_id < 1100
      AND id in (SELECT distinct court_id FROM cases);
  SQL
end

def tco_p2_50_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM (SELECT ca.court_id, count(*) AS cnt
          FROM cases AS ca
            JOIN courts AS co
              ON co.id = ca.court_id
          WHERE co.external_id > 299
            AND co.external_id < 1100
          GROUP BY ca.court_id) AS x
    WHERE cnt >= 50;
  SQL
end

def tj_p2_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM judges AS j
      JOIN courts_judges AS cj
        ON cj.judge_id = j.id
      JOIN courts AS c
        ON c.id = cj.court_id
    WHERE  c.external_id > 299
      AND c.external_id < 1100;
  SQL
end

def tc_2020_p2_appeal_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON co.id = ca.court_id
    WHERE co.external_id > 299
      AND co.external_id < 1100
      AND filled_date >= '2020-01-01'
      AND sub_type = 'Court of Appeals';
  SQL
end

def tc_2020_p2_supreme_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON co.id = ca.court_id
    WHERE co.external_id > 299
      AND co.external_id < 1100
      AND filled_date >= '2020-01-01'
      AND sub_type = 'Supreme Court'
      AND co.type in ('State', 'Federal');
  SQL
end

def tc_p2_pdf_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON co.id = ca.court_id
    WHERE co.external_id > 299
      AND co.external_id < 1100
      AND summary_pdf IS NOT NULL;
  SQL
end

def tc_p2_that_cat_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM cases AS ca
      JOIN courts AS co
        ON co.id = ca.court_id
    WHERE co.external_id > 299
      AND co.external_id < 1100
      AND ca.type IS NOT NULL;
  SQL
end

def tc_p2_lawyers_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM (SELECT ca.id
          FROM cases AS ca
            JOIN cases_lawyers AS cl
              ON ca.id = cl.case_id
            JOIN lawyers AS l
              ON cl.lawyer_id = l.id
            JOIN courts AS c
              ON ca.court_id = c.id
          WHERE c.external_id > 299
            AND c.external_id < 1100
          GROUP BY ca.id) AS x;
  SQL
end

def tc_p2_judges_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM (SELECT ca.id
          FROM cases AS ca
            JOIN cases_judges AS cj
              ON ca.id = cj.case_id
            JOIN judges AS j
              ON cj.judge_id = j.id
            JOIN courts AS c
              ON ca.court_id = c.id
          WHERE c.external_id > 299
            AND c.external_id < 1100
          GROUP BY ca.id) AS x;
  SQL
end

def tco_p1_damage_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM (SELECT DISTINCT c2.id
          FROM civil_damages AS d
            JOIN cases AS c ON c.id = d.case_id
            JOIN courts c2 on c.court_id = c2.id
          WHERE c2.external_id < 300 OR c2.external_id > 1099) AS x;
  SQL
end

def tc_p1_damage_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM civil_damages AS d
      JOIN cases AS c ON c.id = d.case_id
      JOIN courts c2 on c.court_id = c2.id
    WHERE c2.external_id < 300 OR c2.external_id > 1099;
  SQL
end

def tco_p1_closed_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM (SELECT DISTINCT c2.id
          FROM cases AS c
            JOIN courts AS c2 ON c.court_id = c2.id
          WHERE status = 'Closed'
            AND (c2.external_id < 300 OR c2.external_id > 1099)) AS x;
  SQL
end

def tco_p1_act_pdf_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM (SELECT DISTINCT c2.id
          FROM activities AS a
            JOIN cases c on a.case_id = c.id
            JOIN courts c2 on c2.id = c.court_id
          WHERE a.pdf IS NOT NULL
            AND (c2.external_id < 300 OR c2.external_id > 1099)) AS x;
  SQL
end

def total_p1_courts_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM courts
    WHERE external_id < 300 OR external_id > 1099;
  SQL
end

def ta_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM activities;
  SQL
end

def ta_p1_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM activities AS a
      JOIN courts AS co
        ON a.court_id = co.id
    WHERE co.external_id < 300 OR co.external_id > 1099;
  SQL
end

def ta_p2_query
  <<~SQL
    SELECT COUNT(*) AS cnt
    FROM activities AS a
      JOIN courts AS co
        ON a.court_id = co.id
    WHERE co.external_id > 299 AND co.external_id < 1100;
  SQL
end