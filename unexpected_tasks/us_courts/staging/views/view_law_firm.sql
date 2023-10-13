CREATE OR REPLACE VIEW us_courts_staging.view_law_firm
AS SELECT lf.id,
          lf.name,
          lf.type,
          lf.website_url,
          lf.firm_logo_url,
          lfa.street_address,
          lfa.state,
          lfa.city,
          lfa.zip_codea
   FROM us_courts_staging.law_firm_names lf
            JOIN us_courts_staging.law_firm_names_addresses lfna on lf.id = lfna.law_firm_name_id
            JOIN us_courts_staging.law_firm_addresses lfa on lfna.law_firm_address_id = lfa.id