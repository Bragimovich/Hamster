# frozen_string_literal: true

require_relative '../models/runs'

class  Keeper

  def initialize
    @run_id = Runs.create.id
  end

  def update_run_id_sql(run_id)
    sql_text = ""
    sql_text += <<~SQL
        UPDATE `globaldothealth_world_cases` SET deleted = 1
         WHERE touched_run_id <> #{run_id}
           AND deleted = 0;
    SQL
    sql_text
  end

  def get_sql(csv_src, run_id, source)
    sql_text = ""
    sql_text = <<~SQL
    SET @run_id = #{run_id};
    SET @data_source_url = '#{source}';

    CREATE TEMPORARY TABLE `globaldothealth_csv_temporary` LIKE `globaldothealth_world_cases`;

    LOAD DATA LOCAL INFILE '#{csv_src}'
        INTO TABLE `globaldothealth_csv_temporary`
        FIELDS TERMINATED BY ',' ENCLOSED BY '"'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES
        (@case_id, @status, @location, @city, @country, @age, @gender, @date_onset, @date_confirmation, @symptoms, @hospitalised, @date_hospitalisation, @isolated, @date_isolation, @outcome, @contact_comment, @contact_id, @contact_location, @travel_history, @travel_history_entry, @travel_history_start, @travel_history_location, @travel_history_country, @genomics_metadata, @confirmation_method, @source, @source_II, @date_entry, @date_last_modified, @source_III, @source_IV, @country_code)
        SET run_id = @run_id,
            case_id = @case_id,
            status = @status,
            location = @location,
            city = @city,
            country = @country,
            age = @age,
            gender = @gender,
            date_onset = @date_onset,
            date_confirmation = @date_confirmation,
            symptoms = @symptoms,
            hospitalised = @hospitalised,
            date_hospitalisation = @date_hospitalisation,
            isolated = @isolated,
            date_isolation = @date_isolation,
            outcome = @outcome,
            contact_comment = @contact_comment,
            contact_id = @contact_id,
            contact_location = @contact_location,
            travel_history = @travel_history,
            travel_history_entry = @travel_history_entry,
            travel_history_start = @travel_history_start,
            travel_history_location = @travel_history_location,
            travel_history_country = @travel_history_country,
            genomics_metadata = @genomics_metadata,
            confirmation_method = @confirmation_method,
            source = @source,
            source_II = @source_II,
            date_entry = @date_entry,
            date_last_modified = @date_last_modified,
            source_III = @source_III,
            source_IV = @source_IV,
            country_code = @country_code,
            data_source_url = @data_source_url,
            touched_run_id = @run_id,
            md5_hash = MD5(CONCAT_WS('', @case_id, @status, @location, @city, @country,
              @age, @gender, @date_onset, @date_confirmation, @symptoms, @hospitalised,
              @date_hospitalisation, @isolated, @date_isolation, @outcome, @contact_comment,
              @contact_id, @contact_location, @travel_history, @travel_history_entry,
              @travel_history_start, @travel_history_location, @travel_history_country,
              @genomics_metadata, @confirmation_method, @source, @source_II, @date_entry,
              @date_last_modified, @source_III, @source_IV, @country_code));

    INSERT INTO `globaldothealth_world_cases`
    SELECT * FROM `globaldothealth_csv_temporary`
        ON DUPLICATE KEY UPDATE touched_run_id = @run_id, deleted = 0;

    DROP TEMPORARY TABLE `globaldothealth_csv_temporary`;
    SQL
    sql_text
  end

  def store_to_db(csv_src)
    res = Runs.find(@run_id)
    puts ['*'*77, "Store '#{csv_src}' to DataBase"]

    queries = get_sql(csv_src, @run_id, LATEST).split(';')
    queries.each do |query|
      query.strip!
      run_sql(query + ';') unless query.empty?
    end

    run_sql( update_run_id_sql(@run_id) )
    res.status = 'finish'
    res.save
  end

  private

  def run_sql(sql_text)
    puts (['*'*77, Time.now, '*'*77, sql_text])
    Runs.connection.execute(sql_text)
  end

end
