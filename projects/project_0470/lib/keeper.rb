# frozen_string_literal: true

require_relative '../models/runs'

class Keeper < Hamster::Harvester
  def update_run_id(table)
    query = <<~SQL
    UPDATE `#{table}` SET deleted = 1
     WHERE touched_run_id <> #{@run_id}
       AND deleted = 0;
    SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def clear_raw_data(table)
    return unless table.include?('_raw_')
    query = <<~SQL
    TRUNCATE TABLE `#{table}`;
    SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_raw_courts(filename, table)
    query = <<~SQL
    LOAD DATA LOCAL INFILE '#{filename}'
        INTO TABLE `#{table}`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20)
        SET resource_uri              = @p1,
            court_id                  = @p2,
            pacer_court_id            = CASE
              WHEN @p3 = '' THEN null
              ELSE @p3
            END,
            pacer_has_rss_feed        = @p4,
            pacer_rss_entry_types     = @p5,
            date_last_pacer_contact   = CASE
              WHEN @p6 = '' THEN null
              ELSE @p6
            END,
            fjc_court_id              = @p7,
            court_date_modified       = @p8,
            court_in_use              = @p9,
            has_opinion_scraper       = @p10,
            has_oral_argument_scraper = @p11,
            court_position            = @p12,
            court_citation_str        = @p13,
            court_short_name          = @p14,
            court_full_name           = @p15,
            court_url                 = @p16,
            court_start_date          = CASE
              WHEN @p17 = '' THEN null
              ELSE @p17
            END,
            court_end_date            = CASE
              WHEN @p18 = '' THEN null
              ELSE @p18
            END,
            court_jurisdiction        = @p19,
            data_source_url           = @p20;
      SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_raw_political_affiliation(filename, table)
    query = <<~SQL
    LOAD DATA LOCAL INFILE '#{filename}'
        INTO TABLE `#{table}`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12)
        SET resource_uri            = @p1,
            affiliation_id          = @p2,
            person_id               = CASE
              WHEN @p3 = '' THEN null
              ELSE SUBSTRING(@p3, 50)
            END,
            date_created            = @p4,
            date_modified           = @p5,
            political_party         = CASE
              WHEN @p6 = 'd' THEN 'Democratic'
              WHEN @p6 = 'r' THEN 'Republican'
              WHEN @p6 = 'i' THEN 'Independent'
              WHEN @p6 = 'g' THEN 'Green'
              WHEN @p6 = 'l' THEN 'Libertarian'
              WHEN @p6 = 'f' THEN 'Federalist'
              WHEN @p6 = 'w' THEN 'Whig'
              WHEN @p6 = 'j' THEN 'Jeffersonian Republican'
              WHEN @p6 = 'u' THEN 'National Union'
              WHEN @p6 = 'z' THEN 'Reform Party'
              ELSE @p6
            END,
            source                  = @p7,
            date_start              = CASE
              WHEN @p8 = '' THEN null
              ELSE @p8
            END,
            date_granularity_start  = @p9,
            date_end                = CASE
              WHEN @p10 = '' THEN null
              ELSE @p10
            END,
            date_granularity_end    = @p11,
            data_source_url         = @p12;
      SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_raw_schools(filename, table)
    query = <<~SQL
    LOAD DATA LOCAL INFILE '#{filename}'
        INTO TABLE `#{table}`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8)
        SET resource_uri      = @p1,
            school_id         = @p2,
            is_alias_of       = @p3,
            date_created      = @p4,
            date_modified     = @p5,
            school_name       = @p6,
            school_ein        = @p7,
            data_source_url   = @p8;
      SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_raw_education(filename, table)
    query = <<~SQL
    LOAD DATA LOCAL INFILE '#{filename}'
        INTO TABLE `#{table}`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10)
        SET resource_uri      = @p1,
            education_id      = @p2,
            school_id         = CASE
              WHEN @p3 = '' THEN null
              ELSE SUBSTRING(@p3, 69)
            END,
            person_id         = CASE
              WHEN @p4 = '' THEN null
              ELSE SUBSTRING(@p4, 50)
            END,
            date_created      = @p5,
            date_modified     = @p6,
            degree_level      = @p7,
            degree_detail     = @p8,
            degree_year       = CASE
              WHEN @p9 = '' THEN null
              ELSE @p9
            END,
            data_source_url   = @p10;
      SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_raw_persons(filename, table)
    query = <<~SQL
    LOAD DATA LOCAL INFILE '#{filename}'
        INTO TABLE `#{table}`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29, @p30, @p31, @p32, @p33, @p34)
        SET resource_uri          = @p1,
            person_id             = @p2,
            race                  = @p3,
            is_alias_of           = @p9,
            date_created          = @p10,
            date_modified         = @p11,
            date_completed        = CASE
              WHEN @p12 = '' THEN null
              ELSE @p12
            END,
            fjc_person_id         = CASE
              WHEN @p13 = '' THEN null
              ELSE @p13
            END,
            name_slug             = @p14,
            name_first            = @p15,
            name_middle           = @p16,
            name_last             = @p17,
            name_suffix           = @p18,
            date_dob              = CASE
              WHEN @p19 = '' THEN null
              ELSE @p19
            END,
            date_granularity_dob  = @p20,
            date_dod              = CASE
              WHEN @p21 = '' THEN null
              ELSE @p21
            END,
            date_granularity_dod  = @p22,
            dob_city              = @p23,
            dob_state             = @p24,
            dob_country           = @p25,
            dod_city              = @p26,
            dod_state             = @p27,
            dod_country           = @p28,
            gender                = @p29,
            religion              = @p30,
            ftm_total_received    = CASE
              WHEN @p31 = '' THEN null
              ELSE @p31
            END,
            ftm_eid               = CASE
              WHEN @p32 = '' THEN null
              ELSE @p32
            END,
            has_photo             = @p33,
            data_source_url       = @p34;
      SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_raw_positions(filename, table)
    query = <<~SQL
    LOAD DATA LOCAL INFILE '#{filename}'
        INTO TABLE `#{table}`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29, @p30, @p31, @p32, @p33, @p34, @p35, @p36, @p37, @p38, @p39, @p40, @p41)
        SET resource_uri                        = @p1,
            job_id                              = @p2,
            retention_events                    = @p3,
            person_id                           = CASE
              WHEN @p4 = '' THEN null
              ELSE SUBSTRING(@p4, 68)
            END,
            supervisor_id                       = CASE
              WHEN @p5 = '' THEN null
              ELSE SUBSTRING(@p5, 68)
            END,
            predecessor_id                      = CASE
              WHEN @p6 = '' THEN null
              ELSE SUBSTRING(@p6, 68)
            END,
            school_id                           = CASE
              WHEN @p7 = '' THEN null
              ELSE SUBSTRING(@p7, 69)
            END,
            court_id                            = CASE
              WHEN @p8 = '' THEN null
              ELSE SUBSTRING(@p8, 68, LOCATE('/', @p8, 68) - 68)
            END,
            appointer_id                        = CASE
              WHEN @p9 = '' THEN null
              ELSE SUBSTRING(@p9, 53)
            END,
            date_created                        = @p10,
            date_modified                       = @p11,
            position_type                       = @p12,
            job_title                           = @p13,
            sector                              = CASE
              WHEN @p14 = '' THEN null
              ELSE @p14
            END,
            organization_name                   = @p15,
            location_city                       = @p16,
            location_state                      = @p17,
            date_nominated                      = CASE
              WHEN @p18 = '' THEN null
              ELSE @p18
            END,
            date_elected                        = CASE
              WHEN @p19 = '' THEN null
              ELSE @p19
            END,
            date_recess_appointment             = CASE
              WHEN @p20 = '' THEN null
              ELSE @p20
            END,
            date_referred_to_judicial_committee = CASE
              WHEN @p21 = '' THEN null
              ELSE @p21
            END,
            date_judicial_committee_action      = CASE
              WHEN @p22 = '' THEN null
              ELSE @p22
            END,
            judicial_committee_action           = @p23,
            date_hearing                        = CASE
              WHEN @p24 = '' THEN null
              ELSE @p24
            END,
            date_confirmation                   = CASE
              WHEN @p25 = '' THEN null
              ELSE @p25
            END,
            date_start                          = CASE
              WHEN @p26 = '' THEN null
              ELSE @p26
            END,
            date_granularity_start              = @p27,
            date_termination                    = CASE
              WHEN @p28 = '' THEN null
              ELSE @p28
            END,
            termination_reason                  = @p29,
            date_granularity_termination        = @p30,
            date_retirement                     = CASE
              WHEN @p31 = '' THEN null
              ELSE @p31
            END,
            nomination_process                  = @p32,
            vote_type                           = @p33,
            voice_vote                          = @p34,
            votes_yes                           = CASE
              WHEN @p35 = '' THEN null
              ELSE @p35
            END,
            votes_no                            = CASE
              WHEN @p36 = '' THEN null
              ELSE @p36
            END,
            votes_yes_percent                   = CASE
              WHEN @p37 = '' THEN null
              ELSE @p37
            END,
            votes_no_percent                    = CASE
              WHEN @p38 = '' THEN null
              ELSE @p38
            END,
            how_selected                        = @p39,
            has_inferred_values                 = @p40,
            data_source_url                     = @p41;
      SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_raw_dockets(filename, table)
    query = <<~SQL
    LOAD DATA LOCAL INFILE '#{filename}'
        INTO TABLE `#{table}`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29, @p30, @p31, @p32, @p33, @p34, @p35, @p36, @p37, @p38, @p39, @p40, @p41, @p42, @p43, @p44, @p45, @p46, @p47, @p48, @p49, @p50, @p51)
        SET docket_id                         = @p2,
            court_id                          = SUBSTRING(@p3, 50, LOCATE('/', @p3, 50) - 50),
            originating_court_information_id  = CASE
              WHEN @p4 = '' THEN null
              ELSE SUBSTRING(@p4, 91)
            END,
            idb_data_id                       = CASE
              WHEN @p5 = '' THEN null
              ELSE SUBSTRING(@p5, 85)
            END,
            clusters                          = @p6,
            audio_files                       = @p7,
            assigned_to_id                    = CASE
              WHEN @p8 = '' THEN null
              ELSE SUBSTRING(@p8, 50)
            END,
            referred_to_id                    = CASE
              WHEN @p9 = '' THEN null
              ELSE SUBSTRING(@p9, 50)
            END,
            absolute_url                      = @p10,
            date_created                      = @p11,
            date_modified                     = @p12,
            source                            = @p13,
            appeal_from_str                   = CASE
              WHEN @p14 = '' THEN null
              ELSE @p14
            END,
            assigned_to_str                   = CASE
              WHEN @p15 = '' THEN null
              ELSE @p15
            END,
            referred_to_str                   = CASE
              WHEN @p16 = '' THEN null
              ELSE @p16
            END,
            panel_str                         = CASE
              WHEN @p17 = '' THEN null
              ELSE @p17
            END,
            date_last_index                   = CASE
              WHEN @p18 = '' THEN null
              ELSE @p18
            END,
            date_cert_granted                 = CASE
              WHEN @p19 = '' THEN null
              ELSE @p19
            END,
            date_cert_denied                  = CASE
              WHEN @p20 = '' THEN null
              ELSE @p20
            END,
            date_argued                       = CASE
              WHEN @p21 = '' THEN null
              ELSE @p21
            END,
            date_reargued                     = CASE
              WHEN @p22 = '' THEN null
              ELSE @p22
            END,
            date_reargument_denied            = CASE
              WHEN @p23 = '' THEN null
              ELSE @p23
            END,
            date_filed                        = CASE
              WHEN @p24 = '' THEN null
              ELSE @p24
            END,
            date_terminated                   = CASE
              WHEN @p25 = '' THEN null
              ELSE @p25
            END,
            date_last_filing                  = CASE
              WHEN @p26 = '' THEN null
              ELSE @p26
            END,
            case_name_short                   = CASE
              WHEN @p27 = '' THEN null
              ELSE @p27
            END,
            case_name                         = CASE
              WHEN @p28 = '' THEN null
              ELSE @p28
            END,
            case_name_full                    = CASE
              WHEN @p29 = '' THEN null
              ELSE @p29
            END,
            slug                              = CASE
              WHEN @p30 = '' THEN null
              ELSE @p30
            END,
            docket_number                     = CASE
              WHEN @p31 = '' THEN null
              ELSE @p31
            END,
            docket_number_core                = CASE
              WHEN @p32 = '' THEN null
              ELSE @p32
            END,
            pacer_case_id                     = CASE
              WHEN @p33 = '' THEN null
              ELSE @p33
            END,
            cause                             = CASE
              WHEN @p34 = '' THEN null
              ELSE @p34
            END,
            nature_of_suit                    = CASE
              WHEN @p35 = '' THEN null
              ELSE @p35
            END,
            jury_demand                       = CASE
              WHEN @p36 = '' THEN null
              ELSE @p36
            END,
            jurisdiction_type                 = CASE
              WHEN @p37 = '' THEN null
              ELSE @p37
            END,
            appellate_fee_status              = CASE
              WHEN @p38 = '' THEN null
              ELSE @p38
            END,
            appellate_case_type_information   = CASE
              WHEN @p39 = '' THEN null
              ELSE @p39
            END,
            mdl_status                        = CASE
              WHEN @p40 = '' THEN null
              ELSE @p40
            END,
            filepath_ia                       = CASE
              WHEN @p41 = '' THEN null
              ELSE @p41
            END,
            filepath_ia_json                  = CASE
              WHEN @p42 = '' THEN null
              ELSE @p42
            END,
            ia_upload_failure_count           = CASE
              WHEN @p43 = '' THEN null
              ELSE @p43
            END,
            ia_needs_upload                   = CASE
              WHEN @p44 = '' THEN null
              ELSE @p44
            END,
            ia_date_first_change              = CASE
              WHEN @p45 = '' THEN null
              ELSE @p45
            END,
            date_blocked                      = CASE
              WHEN @p46 = '' THEN null
              ELSE @p46
            END,
            blocked                           = @p47,
            appeal_from_id                    = CASE
              WHEN @p48 = '' THEN null
              ELSE SUBSTRING(@p48, 50)
            END,
            tags                              = @p49,
            panel                             = @p50,
            data_source_url                   = @p51
      SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_raw_clusters(filename, table)
    query = <<~SQL
    LOAD DATA LOCAL INFILE '#{filename}'
        INTO TABLE `#{table}`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29, @p30, @p31, @p32, @p33, @p34, @p35, @p36, @p37, @p38, @p39)
        SET cluster_id                = @p2,
            absolute_url              = @p3,
            panel                     = @p4,
            non_participating_judges  = @p5,
            docket_id                 = SUBSTRING(@p6, 51),
            sub_opinions              = @p7,
            citations                 = @p8,
            date_created              = @p9,
            date_modified             = @p10,
            judges                    = CASE
              WHEN @p11 = '' THEN null
              ELSE @p11
            END,
            date_filed                = @p12,
            date_filed_is_approximate = @p13,
            slug                      = @p14,
            case_name_short           = CASE
              WHEN @p15 = '' THEN null
              ELSE @p15
            END,
            case_name                 = @p16,
            case_name_full            = CASE
              WHEN @p17 = '' THEN null
              ELSE @p17
            END,
            scdb_id                   = CASE
              WHEN @p18 = '' THEN null
              ELSE @p18
            END,
            scdb_decision_direction   = CASE
              WHEN @p19 = '' THEN null
              ELSE @p19
            END,
            scdb_votes_majority       = CASE
              WHEN @p20 = '' THEN null
              ELSE @p20
            END,
            scdb_votes_minority       = CASE
              WHEN @p21 = '' THEN null
              ELSE @p21
            END,
            source                    = CASE
              WHEN @p22 = '' THEN null
              ELSE @p22
            END,
            procedural_history        = CASE
              WHEN @p23 = '' THEN null
              ELSE @p23
            END,
            attorneys                 = CASE
              WHEN @p24 = '' THEN null
              ELSE @p24
            END,
            nature_of_suit            = CASE
              WHEN @p25 = '' THEN null
              ELSE @p25
            END,
            posture                   = CASE
              WHEN @p26 = '' THEN null
              ELSE @p26
            END,
            syllabus                  = CASE
              WHEN @p27 = '' THEN null
              ELSE @p27
            END,
            headnotes                 = CASE
              WHEN @p28 = '' THEN null
              ELSE @p28
            END,
            summary                   = CASE
              WHEN @p29 = '' THEN null
              ELSE @p29
            END,
            disposition               = CASE
              WHEN @p30 = '' THEN null
              ELSE @p30
            END,
            history                   = CASE
              WHEN @p31 = '' THEN null
              ELSE @p31
            END,
            other_dates               = CASE
              WHEN @p32 = '' THEN null
              ELSE @p32
            END,
            cross_reference           = CASE
              WHEN @p33 = '' THEN null
              ELSE @p33
            END,
            correction                = CASE
              WHEN @p34 = '' THEN null
              ELSE @p34
            END,
            citation_count            = CASE
              WHEN @p35 = '' THEN null
              ELSE @p35
            END,
            precedential_status       = @p36,
            date_blocked              = CASE
              WHEN @p37 = '' THEN null
              ELSE @p37
            END,
            blocked                   = @p38,
            data_source_url           = @p39;
      SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_raw_opinions(filename, table)
    query = <<~SQL
    LOAD DATA LOCAL INFILE '#{filename}'
        INTO TABLE `#{table}`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26)
        SET opinion_id          = @p2,
            absolute_url        = @p3,
            claster_id          = CASE
              WHEN @p4 = '' THEN null
              ELSE SUBSTRING(@p4, 52)
            END,
            author_id           = CASE
              WHEN @p5 = '' THEN null
              ELSE SUBSTRING(@p5, 50)
            END,
            joined_by           = @p6,
            date_created        = @p7,
            date_modified       = @p8,
            author_str          = CASE
              WHEN @p9 = '' THEN null
              ELSE @p9
            END,
            per_curiam          = @p10,
            joined_by_str       = CASE
              WHEN @p11 = '' THEN null
              ELSE @p11
            END,
            type                = @p12,
            sha1                = @p13,
            page_count          = CASE
              WHEN @p14 = '' THEN null
              ELSE @p14
            END,
            download_url        = CASE
              WHEN @p15 = '' THEN null
              ELSE @p15
            END,
            local_path          = CASE
              WHEN @p16 = '' THEN null
              ELSE @p16
            END,
            plain_text          = CASE
              WHEN @p17 = '' THEN null
              ELSE @p17
            END,
            html                = CASE
              WHEN @p18 = '' THEN null
              ELSE @p18
            END,
            html_lawbox         = CASE
              WHEN @p19 = '' THEN null
              ELSE @p19
            END,
            html_columbia       = CASE
              WHEN @p20 = '' THEN null
              ELSE @p20
            END,
            html_anon_2020      = CASE
              WHEN @p21 = '' THEN null
              ELSE @p21
            END,
            xml_harvard         = CASE
              WHEN @p22 = '' THEN null
              ELSE @p22
            END,
            html_with_citations = CASE
              WHEN @p23 = '' THEN null
              ELSE @p23
            END,
            extracted_by_ocr    = @p24,
            opinions_cited      = @p25,
            data_source_url     = @p26;
      SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_courts(from_table, to_table)
    query = <<~SQL
      INSERT INTO `#{to_table}`
      (SELECT
        null,
        #{@run_id},
        @code := court_id,
        @full := court_full_name,
        @short := court_short_name,
        null,
        null,
        null,
        @start := court_start_date,
        @end := court_end_date,
        @pacer := pacer_court_id,
        @link := court_url,
        @jur := court_jurisdiction,
        data_source_url,
        created_by,
        current_timestamp(),
        current_timestamp(),
        #{@run_id} as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', @code, @full, @short, @start, @end, @pacer, @link, @jur))
      FROM `#{from_table}`)
      ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;
    SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_political_affiliation(from_table, to_table)
    query = <<~SQL
      INSERT INTO `#{to_table}`
      (SELECT
        null,
        #{@run_id},
        @person_id := person_id,
        @party := political_party,
        @start := date_start,
        @g_start := date_granularity_start,
        @end := date_end,
        @g_end := date_granularity_end,
        data_source_url,
        created_by,
        current_timestamp(),
        current_timestamp(),
        #{@run_id} as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', @person_id, @party, @start, @g_start, @end, @g_end))
      FROM `#{from_table}`)
      ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;
    SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_schools(from_table, to_table)
    query = <<~SQL
      INSERT INTO `#{to_table}`
      (SELECT
        null,
        #{@run_id},
        @school_id := school_id,
        @alias_id := CASE
          WHEN is_alias_of = '' THEN null
          ELSE SUBSTR(is_alias_of, 51, LOCATE("/?", is_alias_of) - 51)
        END,
        @name := school_name,
        @ein := school_ein,
        data_source_url,
        created_by,
        current_timestamp(),
        current_timestamp(),
        #{@run_id} as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', @school_id, @alias_id, @name, @ein))
      FROM `#{from_table}`)
      ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;
    SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_education(from_table, to_table)
    query = <<~SQL
      INSERT INTO `#{to_table}`
      (SELECT
        null,
        #{@run_id},
        @person_id := person_id,
        @school_id := school_id,
        @level := degree_level,
        @detail := degree_detail,
        @year := degree_year,
        data_source_url,
        created_by,
        current_timestamp(),
        current_timestamp(),
        #{@run_id} as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', @person_id, @school_id, @level, @detail, @year))
      FROM `#{from_table}`)
      ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;
    SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_persons(from_table, to_table)
    query = <<~SQL
      INSERT INTO `#{to_table}`
      (SELECT
        null,
        #{@run_id},
        @person_id := person_id,
        @alias_id := CASE
          WHEN is_alias_of = '' THEN null
          ELSE SUBSTR(is_alias_of, 50, LOCATE("/?", is_alias_of) - 50)
        END,
        @p1 := name_slug,
        @p2 := name_first,
        @p3 := name_middle,
        @p4 := name_last,
        @p5 := name_suffix,
        @p6 := gender,
        @p7 := race,
        @p8 := religion,
        @p9 := date_dob,
        @p10 := date_granularity_dob,
        @p11 := dob_city,
        @p12 := dob_state,
        @p13 := dob_country,
        @p14 := date_dod,
        @p15 := date_granularity_dod,
        @p16 := dod_city,
        @p17 := dod_state,
        @p18 := dod_country,
        @p19 := fjc_person_id,
        @p20 := ftm_total_received,
        @p21 := ftm_eid,
        data_source_url,
        created_by,
        current_timestamp(),
        current_timestamp(),
        #{@run_id} as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', @person_id, @alias_id, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21))
      FROM `#{from_table}`)
      ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;
    SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_jobs(from_table, to_table)
    query = <<~SQL
      INSERT INTO `#{to_table}`
      (SELECT
        null,
        #{@run_id},
        @p1 := person_id,
        @p2 := supervisor_id,
        @p3 := predecessor_id,
        @p4 := school_id,
        @p5 := court_id,
        @p6 := appointer_id,
        @p7 := position_type,
        @p8 := job_title,
        @p9 := sector,
        @p10 := organization_name,
        @p11 := location_city,
        @p12 := location_state,
        @p13 := date_nominated,
        @p14 := date_elected,
        @p15 := date_recess_appointment,
        @p16 := date_referred_to_judicial_committee,
        @p17 := date_judicial_committee_action,
        @p18 := judicial_committee_action,
        @p19 := date_hearing,
        @p20 := date_confirmation,
        @p21 := date_start,
        @p22 := date_granularity_start,
        @p23 := date_termination,
        @p24 := termination_reason,
        @p25 := date_granularity_termination,
        @p26 := date_retirement,
        @p27 := nomination_process,
        @p28 := vote_type,
        @p29 := voice_vote,
        @p30 := votes_yes,
        @p31 := votes_no,
        @p32 := votes_yes_percent,
        @p33 := votes_no_percent,
        @p34 := how_selected,
        @p35 := has_inferred_values,
        data_source_url,
        created_by,
        current_timestamp(),
        current_timestamp(),
        #{@run_id} as touched_run_id,
        0 as deleted,
        MD5(CONCAT_WS('', @p1,@p2,@p3,@p4,@p5,@p6,@p7,@p8,@p9,@p10,@p11,@p12,@p13,@p14,@p15,@p16,@p17,@p18,@p19,@p20,@p21,@p22,@p23,@p24,@p25,@p26,@p27,@p28,@p29,@p30,@p31,@p32,@p33,@p34,@p35))
      FROM `#{from_table}`)
      ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;
    SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def get_field_from_table(field, table)
    puts '*'*77, "SELECT #{field} from `#{table}`"
    Runs.connection.execute("SELECT #{field} from `#{table}`").to_a.flatten
  end

  def select(field, table, condition)
    puts '*'*77, "SELECT #{field} from `#{table}` where #{condition}"
    Runs.connection.execute("SELECT #{field} from `#{table}` where #{condition}").to_a.flatten
  end

  def set_deleted(name)
    query = "UPDATE cl_#{name} SET deleted = 1 WHERE #{name[0..-2]}_id in (SELECT #{name[0..-2]}_id FROM cl_raw_#{name});"
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store_as_is(name)
    query = <<~SQL
      INSERT INTO `cl_#{name}`
      (SELECT
        null,
        t1.*,
        0 as deleted
      FROM `cl_raw_#{name}` t1)
      ON DUPLICATE KEY UPDATE deleted = 1;
    SQL
    puts '*'*77, query
    Runs.connection.execute(query)
  end

  def store
    run = Runs.create
    @run_id = run.id
    store_courts('cl_raw_courts', 'cl_courts')
    store_political_affiliation('cl_raw_judge_political_affiliation', 'cl_judge_political_affiliation')
    store_schools('cl_raw_schools', 'cl_schools')
    store_education('cl_raw_judge_schools', 'cl_judge_schools')
    store_persons('cl_raw_judge_info', 'cl_judge_info')
    store_jobs('cl_raw_judge_job', 'cl_judge_job')
    TABLES.each { |table| update_run_id(table) }
    TABLES.each { |table| clear_raw_data(table.sub('_', '_raw_')) }
    run.status = 'finish'
  rescue SQLException => e
    pp e.backtrace
    run.status = 'error'
  ensure
    run.save
  end
end
