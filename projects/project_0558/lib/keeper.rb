# frozen_string_literal: true

require_relative '../models/us_courts_ne_model'
EMPTY_SQL_IN = '""'

class Keeper < Hamster::Harvester
  
  attr_reader :run_id
  
  def initialize
    @run_object = safe_operation(NECaseRuns) { |model| RunId.new(model) }
    @run_id = safe_operation(NECaseRuns) { @run_object.run_id }
  end
  
  def reconnect
    # puts '*'*77, "Reconnect!"
    NECaseRuns.connection.reconnect!
    # puts '*'*77, "Reconnect successfully", '*'*77
    Hamster.report to: Manager::WILLIAM_DEVRIES, message: "558_ne_saac_case_*. Reconnecting..."
  rescue StandardError => e
    # puts ['*'*77,  e, e.backtrace]
    sleep 10
    retry     # will retry the reconnect
  end

  def mark_as_started_download
    safe_operation(NECaseRuns) { @run_object.status = 'download started' }
  end

  def mark_as_finished_download
    safe_operation(NECaseRuns) { @run_object.status = 'download finished' }
  end


  def store_2(csv_path, update_flag)
    run = NECaseRuns.create
    @run_id = run.id
    @cases_list_for_sql = all_cases_this_run(update_flag)
    store_case_info("#{csv_path}ne_saac_case_info.csv")
    store_case_party("#{csv_path}ne_saac_case_party.csv")
    store_case_activities("#{csv_path}ne_saac_case_activities.csv")
    store_case_additional_info("#{csv_path}ne_saac_case_additional_info.csv")
    store_case_pdfs_on_aws("#{csv_path}ne_saac_case_pdfs_on_aws.csv")
    store_case_relations_activity_pdf("#{csv_path}ne_saac_case_relations_activity_pdf.csv")

    run.status = 'finish'
  rescue SQLException => e
    pp e.backtrace
    run.status = 'error'
  ensure
    run.save
  end
  
  def get_pdf_md5_hash(case_id)
    NECaseRelationsActivityPdf.where(case_id:case_id).map { |row| row.case_activities_md5 }
  end

  def all_cases_this_run(update_flag)
    return EMPTY_SQL_IN unless update_flag
    run_id = NECaseInfo.order(updated_at: :asc).last.touched_run_id
    cases  = NECaseInfo.where(touched_run_id:run_id).map {|row| row.case_id}
    sql_in = cases.to_s[1..-2]
  end

  def store_case_info(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'ne_saac_case_info'
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        case_name             = NULLIF(@p3, ''),
        case_filed_date       = NULLIF(@p4, ''),
        case_type             = NULLIF(@p5, ''),
        case_description      = NULLIF(@p6, ''),
        disposition_or_status = NULLIF(@p7, ''),
        status_as_of_date     = NULLIF(@p8, ''),
        judge_name            = NULLIF(@p9, ''),
        lower_court_id        = NULLIF(@p10, ''),
        lower_case_id         = NULLIF(@p11, ''),
        data_source_url       = NULLIF(@p12, ''),
        md5_hash              = @p13,
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    queries = sql_text.split(';')
    queries.each do |query|
      query.strip!
      run_sql(query + ';') unless query.empty?
    end
  end

  def store_case_party(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'ne_saac_case_party'
    sql_text = ""
    sql_text = <<~SQL
    UPDATE `#{main_table}` SET deleted=1 WHERE case_id IN (#{@cases_list_for_sql});

    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        party_name            = NULLIF(@p4, ''),
        party_type            = NULLIF(@p5, ''),
        party_description     = NULLIF(@p6, ''),
        is_lawyer             = NULLIF(@p3, ''),
        data_source_url       = NULLIF(@p7, ''),
        md5_hash              = @p8,
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    queries = sql_text.split(';')
    queries.each do |query|
      query.strip!
      run_sql(query.strip + ';') unless query.empty?
    end
  end

  def store_case_activities(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'ne_saac_case_activities'
    sql_text = ""
    sql_text = <<~SQL
    UPDATE `#{main_table}` SET deleted=1 WHERE case_id IN (#{@cases_list_for_sql});

    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        activity_type         = NULLIF(@p5, ''),
        activity_date         = NULLIF(@p3, ''),
        activity_desc         = NULLIF(@p4, ''),
        file                  = NULLIF(@p6, ''),
        data_source_url       = NULLIF(@p7, ''),
        md5_hash              = NULLIF(@p8, ''),
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    queries = sql_text.split(';')
    queries.each do |query|
      query.strip!
      run_sql(query.strip + ';') unless query.empty?
    end
  end

  def store_case_additional_info(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'ne_saac_case_additional_info'
    sql_text = ""
    sql_text = <<~SQL
    UPDATE `#{main_table}` SET deleted=1 WHERE case_id IN (#{@cases_list_for_sql});

    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        lower_court_name      = NULLIF(@p3, ''),
        lower_case_id         = NULLIF(@p4, ''),
        lower_judge_name      = NULLIF(@p5, ''),
        lower_judgement_date  = NULLIF(@p6, ''),
        lower_link            = NULLIF(@p7, ''),
        disposition           = NULLIF(@p8, ''),
        data_source_url       = NULLIF(@p9, ''),
        md5_hash              = NULLIF(@p10, ''),
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    
    queries = sql_text.split(';')
    queries.each do |query|
      query.strip!
      run_sql(query.strip + ';') unless query.empty?
    end
  end

  def store_case_pdfs_on_aws(csv_src)
    # puts "csv_src:", csv_src
    return nil unless File.exist?(csv_src)
    main_table = 'ne_saac_case_pdfs_on_aws'
    
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4, @p5, @p6, @p7)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        source_type           = NULLIF(@p3, ''),
        aws_link              = NULLIF(@p4, ''),
        source_link           = NULLIF(@p5, ''),
        data_source_url       = NULLIF(@p6, ''),
        md5_hash              = NULLIF(@p7, ''),
        run_id                = #{@run_id},
        touched_run_id        = #{@run_id};

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE touched_run_id = #{@run_id}, deleted = 0;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    queries = sql_text.split(';')
    queries.each do |query|
      query.strip!
      run_sql(query.strip + ';') unless query.empty?
    end
  end

  def store_case_relations_activity_pdf(csv_src)
    return nil unless File.exist?(csv_src)
    main_table = 'ne_saac_case_relations_activity_pdf'
    sql_text = ""
    sql_text = <<~SQL
    CREATE TEMPORARY TABLE `#{main_table}__csv` LIKE `#{main_table}`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `#{main_table}__csv`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        (@p1, @p2, @p3, @p4)
        SET
        court_id              = NULLIF(@p1, ''),
        case_id               = NULLIF(@p2, ''),
        case_pdf_on_aws_md5   = NULLIF(@p3, ''),
        case_activities_md5   = NULLIF(@p4, '');

    ALTER TABLE `#{main_table}__csv` DROP COLUMN id;

    INSERT INTO `#{main_table}`
    SELECT null, t2.* FROM `#{main_table}__csv` as t2
    ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

    DROP TEMPORARY TABLE `#{main_table}__csv`;
    SQL

    queries = sql_text.split(';')
    queries.each do |query|
      query.strip!
      run_sql(query.strip + ';') unless query.empty?
    end
  end

  def is_exist(court_id, case_id)
    db_record = NECaseInfo.find_by(court_id: court_id, case_id: case_id)
    return db_record != nil
  end
  
  def store_data(data, model)
    array_hashes = data.is_a?(Array) ? data : [data]
   
    # safe_operation(model) do |model_s|
    model_s = model
    array_hashes.each do |raw_hash|

      find_dig = model_s.find_by(md5_hash: raw_hash[:md5_hash]) rescue nil
      begin
        if find_dig.nil?
          model_s.insert(raw_hash.merge(run_id: @run_id, touched_run_id: @run_id))
        else
          model_s.update(find_dig.id, touched_run_id: @run_id)
        end
      rescue => e
        # puts e.message
        Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "project-#{Hamster::project_number}: #{e.message}\n#{e.backtrace}")
      end
    end
  end

  def add_md5_hash(data_hash, model)
    md5_rel = {NECaseInfo => :info, NECaseParty => :party, NECaseActivities => :activities, NECasePdfsOnAws => :pdfs_on_aws} 

    if md5_rel.has_key?(model)
      md5 = MD5Hash.new(table: md5_rel[model])
      md5_hash = md5.generate(data_hash)
    else
      data_string = data_hash.values.inject('') { |str, val| str += val.to_s }
      md5_hash = Digest::MD5.hexdigest(data_string) 
    end 

    data_hash.merge(md5_hash: md5_hash)
  end

  def run_sql(sql_text)
    # puts (['*'*77, Time.now, '*'*77, sql_text])
    NECaseRuns.connection.execute(sql_text)
  end
  
  def safe_operation(model) 
    begin
      yield(model) if block_given?
    rescue  ActiveRecord::ConnectionNotEstablished, Mysql2::Error::ConnectionError, 
            ActiveRecord::StatementInvalid, ActiveRecord::LockWaitTimeout => e
      begin
        Hamster.report(to: Manager::WILLIAM_DEVRIES, message: "project-#{Hamster::project_number} Keeper: Reconnecting...")
        sleep 10
        model.connection.reconnect!
      rescue => e
        report to: Manager::WILLIAM_DEVRIES, message: "Task#558 Scrape(options) function EXCEPTION: #{e}"
      end
    end
  end
  
end
