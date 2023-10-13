class Keeper
  attr_accessor :model
  attr_reader :table_name, :unchanged

  def initialize(model)
    @model = model
    @table_name = model.table_name
    @unchanged = []
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