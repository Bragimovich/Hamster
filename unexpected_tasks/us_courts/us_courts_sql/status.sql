UPDATE us_case_info uci join raw_uniq_disposition_or_status rudos on uci.disposition_or_status = rudos.disposition_or_status
    SET uci.date_from_dispostion_or_status = rudos.date, uci.cleaned_disposition_or_status = rudos.clean;


UPDATE us_case_info uci join raw_uniq_status_as_of_date rusaod on uci.status_as_of_date = rusaod.status_as_of_date
    SET uci.date_from_status_as_of_date = rusaod.date, uci.cleaned_status_as_of_date = rusaod.clean;