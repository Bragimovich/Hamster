INSERT us_courts.us_case_pdfs_on_aws (court_id, case_id, source_type, aws_link, created_by, md5_hash)
SELECT court_id, case_id, 'info', concat('https://court-cases-activities.s3.amazonaws.com/', REPLACE(file,' ', '%20')), 'Maxim G',
MD5(concat(court_id, case_id, 'info', concat('https://court-cases-activities.s3.amazonaws.com/', REPLACE(file,' ', '%20'))))
from us_courts.us_case_activities_pdf
where case_id not in (SELECT case_id from us_courts.us_case_pdfs_on_aws) and court_id in (35);





INSERT ignore INTO us_courts_analysis.us_case_report_text (court_id, case_id, pdf_on_aws_id, aws_link, pdf_on_aws_md5_hash, text_pdf, text_ocr)
SELECT a_t.court_id, a_t.case_id, pdf.id, pdf.aws_link,pdf.md5_hash, a_t.text_pdf, a_t.text_ocr FROM us_courts.us_case_report_aws_text a_t
join us_courts.us_case_pdfs_on_aws pdf on pdf.case_id=a_t.case_id
where a_t.court_id=35
    and a_t.case_id not in (SELECT case_id from us_courts_analysis.us_case_report_text)