DELETE o FROM cl_csv_opinions o
                  JOIN cl_csv_clusters ccc on o.cluster_id = ccc.id
WHERE ccc.date_filed <'1960-01-01' and ccc.date_filed > '1955-01-01';
