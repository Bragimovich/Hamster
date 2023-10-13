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
    @converter = Converter.new
    @unchanged = []
    @default_exclude_from_md5 = %w[id scrape_frequency md5_hash run_id touched_run_id deleted created_by created_at updated_at]
    @exclude_from_md5 = %w[data_source_url lower_link] #TODO make an option
    @md5_columns = md5_columns
    @md5_sort_order = @md5_columns.map(&:to_sym)
  end

  def safe_operation # will be good add this to run_id class
    begin
      yield if block_given?
    rescue ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout => e
      begin
        logger.info "#{e.message}"
        @connection = @model.connection if @connection.nil?
        @connection.reconnect!
        Hamster.report to: @scraper_name, message: "project-#{Hamster::project_number} Reconnecting..."
      rescue => e
        logger.info e.full_message
        sleep 10
        retry
      end
      retry
    end
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
    end
    data_arr.map! { |data| data.merge!(run_id: @run_id, touched_run_id: @run_id, deleted: 0) }
  end

  def md5_columns(model = @model)
    rejected = @default_exclude_from_md5.concat(@exclude_from_md5)
    column_names = safe_operation { model.column_names }
    column_names.dup.reject! { |item| rejected.include?item}
  end

  def insert(data, md5_hash)
    list_stored_md5 = @model.where(deleted: 0).pluck(:md5_hash).to_set
    list_stored_md5.include?(md5_hash) ? @unchanged.push(md5_hash) : store(data)
  end

  def update_touched_run_id(run_id)
    @unchanged.each do |md5|
      @model.where(md5_hash: md5).update_all(touched_run_id: run_id)
    end
  end

  def update_deleted(run_id)
    @model.where.not(touched_run_id: run_id || nil).update_all(deleted: "1")
  end

  def destroy_where(*options)
    @model.where(*options).destroy_all
  end

  def store(data)
    @model.store(data)
  end

  def truncate
    @model.connection.truncate(@model.table_name)
  end

  def run_sql(sql_text)
    @model.connection.execute(sql_text)
  end
end