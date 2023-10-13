
class RunId
  attr_reader :run_id

  def initialize(client)
    @client = client
    @run_id= get_run_id
    @run_id
  end

  TABLENAME_TLH_RUNS = 'texas_license_holders_runs'

  def get_run_id
    query_select = "SELECT run_id, status, licence_type_run, page_run FROM #{TABLENAME_TLH_RUNS} ORDER BY run_id desc"
    result = @client.query(query_select).first
    if result.nil?
      run_id = 1
      result = {run_id:0}
    elsif result[:status]!='processing'
      run_id = result[:run_id]+1
    else
      run_id = result[:run_id]
    end

    if run_id!=result[:run_id]
      query_insert = "INSERT INTO #{TABLENAME_TLH_RUNS} (run_id) VALUES (#{run_id})"
      @client.query(query_insert)
    end

    return run_id
  end

  def update_column_status
    query = "UPDATE #{TABLENAME_TLH_RUNS} SET status='done' WHERE run_id=#{@run_id}"
    @client.query(query)
  end

end