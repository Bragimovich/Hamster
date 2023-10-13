# frozen_string_literal: true

require_relative '../models/runs'

class Keeper < Hamster::Harvester
  def initialize
    super
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id 
  end

  def update_run_id
    sql_text = <<~SQL
      UPDATE `ny_newyork_bar` SET deleted = 1
      WHERE touched_run_id <> #{@run_id}
      AND deleted = 0;
    SQL
    Runs.connection.execute(sql_text)
  end

  def load_data
    sql_text = <<~SQL
    LOAD DATA LOCAL INFILE '#{Scraper.new.storehouse}store/NYS_Attorney_Registrations.csv' 
    INTO TABLE `ny_newyork_bar_csv` 
    FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED by '\'
    LINES TERMINATED BY '\n' IGNORE 1 LINES;
    SQL
  end

  def run_sql
    Runs.connection.execute("SET @run_id = #{@run_id}")
    Runs.connection.execute("SET @data_source_url = '#{CSV_URL}'")
    Runs.connection.execute("SET @created_by = 'Victor Linnik'")
    Runs.connection.execute("SET @scrape_frequency = 'weekly'")
    sql_text = <<~SQL
      INSERT into ny_newyork_bar
        (SELECT
          null,
          @p1 := registration_number,
          @p2 := CONCAT_WS(' ', first_name, middle_name, last_name, sufix) as name,
          @p3 := first_name,
          @p4 := last_name,
          @p5 := middle_name,
          @p6 := year_admitted as date_admited,
          @p7 := status as registration_status,
          null,
          null,
          @p8 := phone_number as phone,
          null,
          null,
          @p9 := company_name as law_firm_name,
          @p10 := CONCAT_WS(",", IF(street_1 = '', null, street_1), IF(street_2 = '', null, street_2)) as law_firm_address,
          @p11 := CONCAT_WS("-", IF(zip = '', null, zip), IF(zip_plus_four = '', null, zip_plus_four)) as law_firm_zip,
          @p12 := city as law_firm_city,
          @p13 := state as law_firm_state,
          @p14 := county as law_firm_county,
          @p15 := country,
          null,
          @p16 := law_school,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          @p17 := judicial_department_of_admissions as judicial_district,
          null,
          null,
          null,
          null,
          @scrape_frequency,
          @data_source_url,
          @created_by,
          current_timestamp(),
          current_timestamp(),
          @run_id,
          @run_id as touched_run_id,
          0,
          MD5(CONCAT_WS('', @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17))
      FROM ny_newyork_bar_csv)
      on duplicate key update touched_run_id = @run_id, deleted = 0;
    SQL
  
    Runs.connection.execute(sql_text)
  end

  def finish
    @run_object.finish
  end
end
