

class CommonModel < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
  self.logger = Logger.new(STDOUT)
  self.table_name = 'common__runs'
  EXCLUDE_TABLE_COMMON = ["common__runs"]
  def self.registry
    sql = Arel.sql("SELECT id, prefix, char_length(prefix) AS pref_length FROM registry")
    connection.select_all(sql)
  end

  def self.runs
    @runs_id = self.create.id
  end

  def self.runs_finish
    r = self.find(@runs_id)
    r.status = 'finished'
    r.save
  end

  def self.runs_errors
    r = self.find(@runs_id)
    r.status = 'errors'
    r.save
  end

  def self.updating_tables(current_table)
    length_pref = 8

    sql = Arel.sql("SELECT SUBSTR(TABLE_NAME, char_length('common__')+1 ) AS suffix
FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'crime_perps__step_1'
AND TABLE_NAME LIKE 'common__%' AND TABLE_NAME NOT IN ('#{EXCLUDE_TABLE_COMMON.join(",")}')")

    connection.select_all(sql)
  end

  def self.column_mapping(current_table, suffix_name_table)
    table_name = current_table["prefix"] + suffix_name_table
    table_common = "common__" + suffix_name_table
    all_column = Arel.sql("SELECT t2.* FROM
( SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='crime_perps__step_1'
AND TABLE_NAME='#{table_name}' ) AS t2
    CROSS JOIN (SELECT  TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='crime_perps__step_1'
AND TABLE_NAME='#{table_common}' ) AS t1 ON t2.COLUMN_NAME = t1.COLUMN_NAME
WHERE t2.COLUMN_NAME NOT IN ('run_id', 'created_by', 'created_at', 'updated_at', 'id', 'touched_run_id')")

    connection.select_all(all_column)
  end

  def self.run_update
    runs
    table_registry = registry

    begin
    table_registry.each do |table|
      res_updating_tables = updating_tables(table)
      run_id = @runs_id
      res_updating_tables.each do |suffix_column|
        @table = table
        @suffux_column = suffix_column
        res = column_mapping( table, suffix_column["suffix"] )
        column_map = res.map { |item| item["COLUMN_NAME"] }.join(" ,")


        column_map_dst_insert = "origin_table_id, origin_id, run_id, " + column_map + ", created_by, touched_run_id"
        column_map_src_insert = "#{table["id"]}, t0.id, #{run_id}, " + res.map { |item| "t0."+item["COLUMN_NAME"] }.join(", ") + ", 'Mikhail Golovanov', #{run_id}"


        column_map_dst_update =  res.map { |item| "t0." + item["COLUMN_NAME"] + "=" + "t1." + item["COLUMN_NAME"] }.join(", ")

        sql_for_select_update = "SELECT t0.* FROM #{table["prefix"]}#{suffix_column["suffix"]} t0 LEFT JOIN common__#{suffix_column["suffix"]} t1 ON t1.origin_id = t0.id AND t1.origin_table_id = #{table["id"]} WHERE t1.origin_id IS NOT NULL"
        sql_update = "UPDATE  (#{sql_for_select_update}) t1, common__#{suffix_column["suffix"]} t0 SET #{column_map_dst_update}, t0.touched_run_id=#{run_id} WHERE t0.origin_id = t1.id AND t0.origin_table_id = #{table["id"]}"


        sql_for_select_insert = "SELECT #{column_map_src_insert} FROM #{table["prefix"]}#{suffix_column["suffix"]} t0 LEFT JOIN common__#{suffix_column["suffix"]} t1 ON t1.origin_id = t0.id AND t1.origin_table_id = #{table["id"]} WHERE t1.origin_id IS NULL"
        sql_insert = "INSERT IGNORE INTO common__#{suffix_column["suffix"]} (#{column_map_dst_insert}) #{sql_for_select_insert}"

        sql_arel = Arel.sql(sql_update)

        connection.execute(sql_arel)

        sql_arel = Arel.sql(sql_insert)

        connection.execute(sql_arel)
        runs_finish
      end
    end
    rescue StandardError => e
      pp e.to_s
      pp @table
      pp @suffux_column
      runs_errors
    end
  end


end