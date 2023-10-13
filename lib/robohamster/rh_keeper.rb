# frozen_string_literal: true

class RoboHamsterKeeper < Hamster::Keeper

  attr_reader :models_db

  def initialize(db_location, column_in_table, column_type)
    @db_location = db_location

    make_new_tables(column_in_table, column_type)

    @models_db = {}
    column_in_table.each_key do |table_name|
      @models_db[table_name] = active_record_model(table_name)
    end
    @models_db
  end

  def insert_in_all_tables(elements, md5_hashes)
    existed_rows = {}
    error_count = 0
    elements.each do |table_name, data|
      existed_md5_hash = get_existed(md5_hashes[table_name], table_name)
      existed_rows[table_name] = existed_md5_hash.length
      data_to_db = []
      data.each { |row| data_to_db.push(row) if !row[:md5_hash].in?(existed_md5_hash) }
      begin
        insert_all(table_name, data_to_db)
      rescue ActiveRecord::ValueTooLong => e
        error_count += 1
        column, el_number = e.message.match(/Data too long for column '(.+)' at row (\d+)/)[1, 2]
        Hamster.logger.error(e.message)
        Hamster.logger.debug("#{e.message}:\n #{data_to_db[el_number.to_i][column]}")
        data_to_db.delete_at(el_number.to_i)
        if error_count < 4
          retry
        else
          assert "Too many errors ValueTooLong. Check logs. Exiting..."
        end
      end
    end
    existed_rows
  end


  def insert_all(table_name, data)
    @models_db[table_name].insert_all(data) if !data.empty?
  end


  def get_existed(md5_hashes, table_name)
    existed_md5_hash = []
    rows = @models_db[table_name].where(md5_hash:md5_hashes)
    rows.each {|row| existed_md5_hash.push(row[:md5_hash])}
    existed_md5_hash
  end


  def active_record_model(table_name, database_name = :robohamster)
    class_table = table_name.camelize

    assert "Bad table_name" if class_table.match(/\W/)
    eval("""
        class #{class_table} < ActiveRecord::Base
          self.inheritance_column = :_type_disabled
          self.table_name = '#{table_name}'
          establish_connection(Storage[host: :#{@db_location['server'].downcase}, db: :#{@db_location['schema']}])
        end
      """)

    eval(class_table)

  end

  def make_new_tables(column_in_table, column_types, database_name = :robohamster)
    client = connect_to_db
    column_in_table.each do |table_name, columns|
      sql_query = sql_make_table(table_name, columns, column_types[table_name])
      client.query(sql_query)
    end
  end

  private

  def connect_to_db #us_court_cases
    Mysql2::Client.new(Storage[host: :db02, db: @db_location['schema'].to_sym].except(:adapter).merge(symbolize_keys: true))
  end

  def sql_make_table(table_name, columns, column_types)

    sql_string = "
        CREATE TABLE IF NOT EXISTS `#{table_name}`
        (
          `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,"

    columns.each do |column|
      type =
        case column_types[column]
        when 'date'
          'DATETIME'
        when 'text'
          'LONGTEXT'
        when 'number'
          'BIGINT(20)'
        else
          'VARCHAR(511)'
        end

      sql_string += " `#{column}`           #{type},"
    end

    sql_string += "
          `data_source_url` VARCHAR(255)       DEFAULT 'https://www.brown.senate.gov/newsroom/press-releases?expanded=true&pagenum_rs=1',
          `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
          `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
          `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

          `md5_hash`        VARCHAR(255),
          UNIQUE KEY `md5` (`md5_hash`),
          UNIQUE KEY `link` (`link`)
        ) DEFAULT CHARSET = `utf8mb4`
          COLLATE = utf8mb4_unicode_520_ci;"

    sql_string

  end
end