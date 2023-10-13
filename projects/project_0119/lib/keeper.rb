class Keeper
  attr_accessor :model
  attr_reader :table_name, :unchanged

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
    @unchanged = []
    @default_exclude_from_md5 = %w[id scrape_frequency md5_hash run_id touched_run_id deleted created_by created_at updated_at]
    @exclude_from_md5 = %w[data_source_url lower_link] #TODO make an option
    @md5_columns = md5_columns
    @md5_sort_order = @md5_columns.map(&:to_sym)
  end

  def md5_columns(model = @model)
    rejected = @default_exclude_from_md5.concat(@exclude_from_md5)
    column_names = safe_operation { model.column_names }
    column_names.dup.reject! { |item| rejected.include?item}
  end

  def update_md5(model = @model)
    safe_operation do
      model.update_all("md5_hash = MD5(CONCAT_WS('', #{md5_columns.join(', ')}))")
    end
  end

  def insert_all(md5 = true, data)
    safe_operation {
      return if data.nil?

      data = add_run_id(md5, data)

      @model.insert_all(data)
    }
  end

  def add_run_id(md5 = true, data)
    data_arr = data.is_a?(Array) ? data : [data]
    data_arr.map! { |data| @converter.clean_data(data) }
    if md5
      data_arr.map! do |data|
        md5_data = data.slice(*@md5_sort_order)
        data.merge!(md5_hash: @converter.to_md5(md5_data)) unless data.key?(:md5_hash)
        data
      end
      list_stored_md5 = @model.where(deleted: 0).pluck(:md5_hash).to_set
      data_arr.each do |data|
        list_stored_md5.include?(data[:md5_hash]) ? @unchanged.push(data[:md5_hash]) : data.merge!(run_id: @run_id)
      end
    end
    #data.reject { |hash| list_stored_md5.include?(hash[:md5_hash]) } # OPTIMIZE delete this?
    data_arr.map! { |data| data.merge!(touched_run_id: @run_id, deleted: 0) }
  end


  def safe_operation(retries = 15) # TODO prevent possible data lost + test wrong data type error
    begin
      yield if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        Hamster.logger.info "#{e.full_message}"
        sleep 100
        # Hamster.report(to: @scraper_name, message: "project-#{Hamster::project_number} Keeper: Reconnecting...")
        @connection = @model.connection if @connection.nil?
        @connection.reconnect!
        ActiveRecord::Base.establish_connection(Storage.use(host: :db02, db: :mysql)).connection.reconnect!
      rescue *connection_error_classes => e
        Hamster.logger.info "#{e.full_message}"
        sleep 100
        retry if retries > 0
      end
      retry if retries > 0
    end
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end

  def drop_indexes
    safe_operation {
      @connection.indexes(@table_name).each do |index|
        remove_index @table_name, name: index.name
      end
    }
  end

  def add_indexes(indexes)
    names = indexes.map(&:name)
    names.each do |name|
      safe_operation {
        @connection.add_index(@table_name, name) # add .to_sym ???
      }
    end
  end

  # def update_touched_run_id(run_id)
  #   @unchanged.each do |md5|
  #     @model.where(md5_hash: md5).update_all(touched_run_id: run_id)
  #   end
  # end

  def update_deleted
    safe_operation {
      @model.where.not(touched_run_id: @run_id || nil).update_all(deleted: "1")
    }
  end

  def destroy_where(*options)
    safe_operation {
      @model.where(*options).destroy_all
    }
  end

  def store(data)
    safe_operation {
      @model.store(data)
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