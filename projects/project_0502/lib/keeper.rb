require_relative '../lib/converter'

class Keeper
  attr_accessor :model
  attr_reader :table_name, :unchanged

  # rel_models = [{ rel_model: CaseRelationsInfoPdf, rel_keys: [:case_info_md5] }]
  def initialize(model, run_id = 0, scraper_name = 'vyacheslav pospelov', rel_models = [])
    @model = model
    @rel_models = rel_models
    @scraper_name = scraper_name
    @connection = safe_operation { @model.connection }
    @table_name = safe_operation { @model.table_name }
    @current_database = safe_operation { @connection.current_database } # @model.connection_db_config.database ???
    @column_names = safe_operation { @model.column_names }
    @indexes = safe_operation { @connection.indexes(@table_name) }
    @run_id = run_id
    @converter = Converter.new(@run_id)
    @unchanged = [] #TODO replace using file
    @default_exclude_from_md5 = %w[id scrape_frequency md5_hash run_id touched_run_id deleted created_by created_at updated_at]
    @exclude_from_md5 = %w[data_source_url lower_link] #TODO make an option
    @md5_columns = md5_columns
    @md5_sort_order = @md5_columns.map(&:to_sym)
  end

  def md5_columns(model = @model)
    rejected = @default_exclude_from_md5.concat(@exclude_from_md5)
    column_names = safe_operation { model.column_names }
    column_names.dup.reject! { |item| rejected.include?(item) }
  end

  def safe_operation # will be good add this to run_id class
    begin
      yield if block_given?
    rescue ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout => e
      begin
        puts "#{e.message}"
        puts '*'*77, "Reconnect!", '*'*77
        @connection = @model.connection if @connection.nil?
        @connection.reconnect!
        Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Reconnecting..."
        sleep 10
      rescue => e
        puts e.full_message
        sleep 10
        retry
      end
      retry
    end
  end

  #TODO make safe for connection lost
  def delete_duplicates(model = @model, rel_models = @rel_models)
    #for  ca_saac_case_activities
    #"foreign key (md5_hash) references ca_saac_case_relations_activity_pdf (case_activities_md5) on delete cascade,"
    #for  ca_saac_case_pdfs_on_aws
    #"foreign key (md5_hash) references ca_saac_case_relations_activity_pdf (case_pdf_on_aws_md5) on delete cascade,"
    #"select * from case_activities_md5 group by court_id, case_id, activity_date, activity_desc, activity_type having count(*) > 1"

    md5_columns = md5_columns(model)

    md5_associations = []
    safe_operation {
      model.group("#{md5_columns.join(', ')}").having("count(*) > 1").each do |row|
        md5_data = model.where(id: row[:id]).as_json.first.slice(*md5_columns)
        correct_md5 = @converter.to_md5(md5_data)
        duplicates = model.where(md5_data) # duplicates with same data rows and different md5
        duplicates.each_with_index do |duplicate, index|
          # MODIFY possible options: using 1) first elem 2) last elem 4) using index 3)data having less nil values in a row
          unless index == duplicates.size - 1 # 0 or duplicates.size - 1          deleting all duplicates expect first
            # before deleting need save deleted md5 and then replace them in relation table with new md5
            md5_associations << { id: duplicate[:id], old_md5: duplicate[:md5_hash], new_md5: correct_md5 }
            duplicate.delete
          end
        end
      end
    }
    if rel_models
      rel_models.each do |relation|
        relation[:rel_keys].each do |key|
          md5_associations.each do |hash|
            safe_operation {
              if relation[:rel_model].where(key => hash[:old_md5]).blank?
                puts "in rel_model key = #{key} , md5 = #{hash[:old_md5]} not exist"
              else
                puts "in rel_model key = #{key} , md5 = #{hash[:old_md5]} exist"
                relation[:rel_model].where(key => hash[:old_md5]).update_all(key => hash[:new_md5])
              end
            }
          end
        end
        # fix md5 in relation table too
        delete_duplicates(relation[:rel_model], nil)
        safe_operation {
          relation[:rel_model].update_all("md5_hash = MD5(CONCAT_WS('', #{md5_columns(relation[:rel_model]).join(', ')}))")
        }
      end
    end

    #model.update_all("md5_hash = MD5(CONCAT_WS('', #{@md5_columns.join(', ')}))")
    md5_associations
  end

  def fix_empty_touched_run_id
    #TODO add touched_run_id: nil || 0
    safe_operation {
      @model.where(touched_run_id: nil).update_all(touched_run_id: @run_id - 1, deleted: 1) if @run_id > 1
    }
    #TODO add run_id: nil || 0
    safe_operation {
      @model.where(run_id: 0).update_all(run_id: @run_id - 1, touched_run_id: @run_id - 1, deleted: 1) if @run_id > 1
    }
  end

  def fix_wrong_md5(model = @model, md5_columns = @md5_columns)
    #class TempModel < ActiveRecord::Base; end

    #run_sql("CREATE TABLE IF NOT EXISTS #{@table_name}_temporary LIKE #{@table_name};")
    #run_sql("INSERT INTO #{@table_name}_temporary SELECT * FROM #{@table_name} GROUP BY ID;")

    #"SHOW CREATE TABLE prod_db.sales_order"
    delete_duplicates

    #model.table_name = "#{@table_name}_temporary"
    #model.table_name = "#{@table_name}"
    safe_operation { model.update_all("md5_hash = MD5(CONCAT_WS('', #{md5_columns.join(', ')}))") }

    #run_sql("DROP TABLE IF EXISTS #{@table_name}_temporary;")
  end

  def update_md5(model = @model)
    safe_operation { model.update_all("md5_hash = MD5(CONCAT_WS('', #{@md5_columns.join(', ')}))") }
  end

  # replace_substring(@md5_columns, '&amp;', '&')
  def replace_substring(replaced_columns, substring, replace_to, md5 = true)
    find_string = replaced_columns.map {|column_name| column_name += " LIKE ?"}.join(' OR ')
    update_string = replaced_columns.map do
    |column_name| column_name += " = REPLACE(#{column_name}, '#{substring}', '#{replace_to}')"
    end.join(', ')
    update_string = update_string.join(", md5_hash = MD5(CONCAT_WS('', #{@md5_columns.join(', ')}))") if md5
    safe_operation { @model.where(find_string, "%#{substring}%").update_all(update_string) }
  end

  def prepare_data(md5 = true, data)
    return if data.nil?

    data_arr = data.is_a?(Array) ? data : [data]
    data_arr.map! { |data| @converter.clean_data(data) }
    unchanged_arr = []

    if md5
      data_arr.map! do |data|
        md5_data = data.slice(*@md5_sort_order)
        data.merge!(md5_hash: @converter.to_md5(md5_data)) unless data.key?(:md5_hash)
        data
      end
      safe_operation {

        list_stored_md5 = @model.where(deleted: 0).pluck(:md5_hash).to_set
        data_arr.each do |data|
          if list_stored_md5.include?(data[:md5_hash])
            @unchanged.push(data[:md5_hash])
            unchanged_arr << data
          else
            data.merge!(run_id: @run_id)
          end
        end
        data_arr.reject! { |data| list_stored_md5.include?(data[:md5_hash]) }
      }
    end

    distinct_keys = unchanged_arr.map(&:keys).flatten.uniq
    unchanged_arr.map! do |data|
      distinct_keys.each { |key| data[key] ||= nil }
      data
    end

    unchanged_arr.map! { |data| data.merge!(touched_run_id: @run_id, deleted: 0) }

    distinct_keys = data_arr.map(&:keys).flatten.uniq
    data_arr.map! do |data|
      distinct_keys.each { |key| data[key] ||= nil }
      data
    end

    data_arr.map! { |data| data.merge!(touched_run_id: @run_id, deleted: 0) }
    [data_arr, unchanged_arr]
  end

  def insert(data)
    safe_operation {
      data = prepare_data(data)[0].first

      return if data.nil?

      list_stored_md5 = @model.where(deleted: 0).pluck(:md5_hash).to_set
      list_stored_md5.include?(data[:md5_hash]) ? @unchanged.push(data[:md5_hash]) : store(data)
    }
  end

  # def insert_all(md5 = true, data)
  #   safe_operation {
  #     data, unchanged_data = prepare_data(md5, data)
  #
  #     return if data.nil?
  #
  #     @model.insert_all(data)
  #   }
  # end

  def upsert_all(md5 = true, data)
    data, unchanged_data = prepare_data(md5, data)

    safe_operation {
      @model.upsert_all(data) unless data.blank?
    }

    safe_operation {
      @model.upsert_all(unchanged_data) unless unchanged_data.blank?
    }
  end

  def transaction_store(data)
    safe_operation {
      data_arr = data.is_a?(Array) ? data : [data]
      #data_arr.map! { |data| @converter.clean_data(data) }
      @connection.transaction do
        data_arr.each do |data|
          @model.store(@converter.clean_data(data))
        end
      end
    }
  end

  def drop_indexes
    safe_operation {
      @indexes = @connection.indexes(@table_name)
      @connection.indexes(@table_name).each do |index|
        @connection.remove_index @table_name, name: index.name
      end
      @indexes
    }
  end

  def add_indexes(indexes)
    safe_operation {
      names = indexes.map(&:name)
      names.each do |name|
        @connection.add_index(@table_name, name) # add .to_sym ???
      end
    }
  end

  def update_touched_run_id
    safe_operation {
      @unchanged.each do |md5|
        @model.where(md5_hash: md5).update_all(touched_run_id: @run_id, deleted: 0)
      end
    }
  end

  def update_deleted
    safe_operation {
      @model.where.not(touched_run_id: @run_id).update_all(deleted: "1")
    }
  end

  def destroy_where(*options)
    safe_operation {
      @model.where(*options).destroy_all
    }
  end

  def store(data)
    safe_operation {
      @model.store(@converter.clean_data(data))
    }
  end

  def truncate
    safe_operation {
      @connection.truncate(@model.table_name)
    }
  end

  def run_sql(sql_text)
    safe_operation {
      @connection.execute(sql_text)
    }
  end
end