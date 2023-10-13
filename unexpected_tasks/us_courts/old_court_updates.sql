UPDATE us_case_activities
SET additional_or_old=1, deleted=0
WHERE court_id in (90,93,94) and created_by='dshilenko';

UPDATE us_case_activities
SET additional_or_old=1, deleted=0
WHERE court_id in (92,95) and created_by='vsviridov';


UPDATE us_case_activities
SET additional_or_old=1, deleted=0
WHERE court_id in (86, 91) and created_by='Octavian';


UPDATE us_case_activities
SET additional_or_old=1, deleted=0
WHERE court_id in (81,83,88) and created_by='Anton Storchak'