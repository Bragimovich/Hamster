module Task85CsvSave
  attr_accessor :run_id, :year_1, :year_2, :data_source, :created_by, :touched_run_id

  def csv_save(file)
    puts self.table_name

    sql_create = <<~SQL
            LOAD DATA LOCAL INFILE '#{file}'
                INTO TABLE `#{self.table_name}`
                FIELDS TERMINATED BY ',' ENCLOSED BY '"'
                LINES TERMINATED BY '\n'
                IGNORE 1 LINES
                (@state_fips, @country_fips, @dst_state_fips, 
      @dst_county_fips, @dst_state_name, 
      @dst_county_name, @number_of_returns, 
      @number_of_exemptions, @adjusted_gross_income)
                SET 
                    run_id = '#{@run_id}',
                    year_1 = '#{@year_1}',
                    year_2 = '#{@year_2}',
                    origin_state_fips = @state_fips,
                    origin_country_fips = @country_fips,
                    destination_state_fips = @dst_state_fips,
                    destination_county_fips = @dst_county_fips,
                    destination_state_name = @dst_state_name,
                    destination_county_name = @dst_county_name,
                    number_of_returns = @number_of_returns,
                    number_of_exemptions = @number_of_exemptions,
                    adjusted_gross_income = @adjusted_gross_income,
                    data_source_url = '#{@data_source}',
                    created_by = '#{@created_by}',
                    touched_run_id = '#{@touched_run_id}',
                    md5_hash = MD5(REPLACE(CONCAT_WS('','#{@year_1}', '#{@year_2}',
 @state_fips, @country_fips, @dst_state_fips, @dst_county_fips, @dst_state_name, 
@dst_county_name, @number_of_returns, @number_of_exemptions, @adjusted_gross_income), ' ', ''));
    SQL

    self.connection.execute(sql_create)

    pp
  end
end
