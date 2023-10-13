# In process ....



# us_case_info – {"id"=>9, "court_name"=>"Kentucky Supreme Court", "court_state"=>"Kentucky", "court_type"=>"State",
# "case_name"=>"RICHARD M. KOLBELL  PHD., ABPP VS CHERYL  CLARK", "case_id"=>"2016-SC-0085",
# "case_filed_date"=>#<Date: 2016-02-22 ((2457441j,0s,0n),+0s,2299161j)>,
# "case_description"=>"DISCRETIONARY REVIEW - CIVIL - REGULAR CIVIL", "case_type"=>"CIVIL", "disposition_or_status"=>"",
# "status_as_of_date"=>"FINAL", "judge_name"=>"", "scrape_dev_name"=>"Aqeel",
# "data_source_url"=>"https://appellatepublic.kycourts.net/case/summary/478edd52a823820f5890248be8e1c76fcb5a8449189262772c037a5962b1250b",
# "created_at"=>2021-04-05 12:05:20 +0300, "updated_at"=>2021-04-18 23:56:07 +0300, "scrape_frequency"=>"daily",
# "last_scrape_date"=>#<Date: 2021-04-05 ((2459310j,0s,0n),+0s,2299161j)>,
# "next_scrape_date"=>#<Date: 2021-04-06 ((2459311j,0s,0n),+0s,2299161j)>,
# "expected_scrape_frequency"=>"daily", "pl_gather_task_id"=>177584176, "court_id"=>18}



def connect_to_db(database=:us_court_cases) #us_court_cases
  Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
end


def start_history_transfer(days=0)
  limit = 5000
  tables = %w[info party activities lawyer]
  client = connect_to_db(database=:usa_raw)
  result = get_court_id(client)
  client.close
  courts = Hash.new()
  result.map { |row| courts[row[:court_id]]=row[:scrape_dev_name]}
  courts.keys.each do |court_id|
    client = connect_to_db(database=:usa_raw)
    p "Court: #{court_id}"
    current_run = HistoryRunId.new(court_id, courts[court_id], client)

    if current_run.run_id.nil?
      puts 'The court was updated today'
      next
    end
    tables.each do |table|
      p table
      column_status = table+'_status'
      if current_run.status[column_status.to_sym]!='done'
        info = MakeHistory.new(table, court_id, current_run.run_id, client)
        info.transfer_date(days, limit)
        current_run.update_column_status(table) #put in runs table that the table is done
        puts "Done!"
        puts
      else
        puts "Done in previous transfer"
      end
    end
    current_run.update_general_status
    client.close
  end

end

def get_court_id(client)
  query = "SELECT court_id, scrape_dev_name FROM usa_raw.us_courts_table"
  client.query(query)
end

# Work with run_id: get last run_id, change status
class HistoryRunId
  attr_reader :run_id, :status

  def initialize(court_id, scrape_dev_name, client)
    @client = client
    @court_id = court_id
    @scrape_dev_name = scrape_dev_name
    @run_id, @status = get_run_id
  end

  TABLENAME = 'us_courts_history_runs'

  def get_run_id
    query_select = "SELECT run_id, status, info_status, activities_status, party_status, lawyer_status, created_at
            FROM #{TABLENAME} WHERE court_id=#{@court_id} ORDER BY run_id desc"
    result = @client.query(query_select).first
    if result.nil?
      run_id = 1
      result = {run_id:0}
    elsif result[:status]!='processing'
      return nil if result[:created_at].day-Date.today.day==0
      run_id = result[:run_id]+1
    else
      run_id = result[:run_id]
    end

    if run_id!=result[:run_id]
      query_insert = "INSERT INTO #{TABLENAME} (run_id, court_id, created_by) VALUES (#{run_id}, #{@court_id}, '#{@scrape_dev_name}')"
      @client.query(query_insert)
      result = {info_status: 'processing', activities_status: 'processing', party_status: 'processing', lawyer_status: 'processing'}
    end

    return run_id, result
  end

  def update_column_status(column='info')
    column_name = column.to_s + '_status'
    query = "UPDATE #{TABLENAME} SET #{column_name}='done' WHERE court_id=#{@court_id} AND run_id=#{@run_id}"
    @client.query(query)
    @status[column_name.to_sym] = 'done'
  end

  def update_general_status
    query = "SELECT run_id FROM #{TABLENAME} WHERE court_id=#{@court_id} AND run_id=#{@run_id} AND info_status='done'
          AND activities_status='done' AND party_status='done' AND lawyer_status='done'"
    result = @client.query(query).first

    if result.nil?
      puts "Something wrong. Some column didn't end"
    else
      query = "UPDATE #{TABLENAME} SET status='done' WHERE court_id=#{@court_id} AND run_id=#{@run_id}"
      @client.query(query)
    end
  end
end



# Transfer all data to history table for the tablename and the court_id
class MakeHistory
  def initialize(tablename, court_id, run_id, client)
    @tablename = tablename.to_s
    @tablename_columns =  COLUMNS[tablename.to_sym]
    @client = client
    @court_id = court_id
    @current_run_id = run_id
    update_run_id_for_existing
  end

  COLUMNS = {
    :info => {
      :general => %i[court_name court_state court_type court_id case_name case_id case_description case_type
                       disposition_or_status status_as_of_date judge_name data_source_url scrape_dev_name pl_gather_task_id md5_hash],
      :dates => %i[case_filed_date last_scrape_date next_scrape_date],
    },
    :party => {
      :general =>
        %i[court_id case_number party_name party_type party_address party_city party_state party_zip data_source_url
        scrape_dev_name pl_gather_task_id law_firm is_lawyer party_description scrape_frequency expected_scrape_frequency md5_hash],
      :dates => %i[last_scrape_date next_scrape_date],
    },
    :activities => {
      :general => %i[court_id case_id activity_decs activity_type activity_pdf scrape_dev_name
            data_source_url pl_gather_task_id scrape_frequency expected_scrape_frequency file md5_hash],
      :dates =>  %i[activity_date last_scrape_date next_scrape_date],
    },
    :lawyer => {
      :general => %i[court_id case_number defendant_lawyer defendant_lawyer_firm plantiff_lawyer plantiff_lawyer_firm scrape_dev_name
            data_source_url scrape_frequency expected_scrape_frequency pl_gather_task_id md5_hash],
      :dates => %i[last_scrape_date next_scrape_date]
    }
  }

  #_______DATABASE______

  def get_root_data(days, limit, page=0)
    offset = limit * page
    dates_column = ", #{@tablename_columns[:dates].join(', ')}" if !@tablename_columns[:dates].empty?
    query = "SELECT #{@tablename_columns[:general].join(', ')} #{dates_column} FROM us_case_#{@tablename}
             WHERE court_id=#{@court_id} AND md5_hash not in
                (SELECT md5_hash FROM us_case_#{@tablename}_history
                            WHERE court_id=#{@court_id}) "# AND touched_run_id!=#{@current_run_id})"
    query += "AND Date(updated_at)>CURDATE()-#{days} "  if days > 0
    query += "LIMIT #{limit} OFFSET #{offset}" if limit>0
    @client.query(query)
  end

  def insert_data(data, run_id)
    general_data = ''
    @tablename_columns[:general].each do |q|
      data[q]=@client.escape(data[q]) if data[q].instance_of? String
      general_data+=" '#{data[q]}', "
    end


    @tablename_columns[:dates].each do |q|
      if data[q]==nil
        general_data += "'0000-00-00', "
      else
        general_data += "'#{data[q]}', "
      end
    end

    #general_data += "'#{data[:md5_hash]}'"
    date_table = ", #{@tablename_columns[:dates].join(', ')}" if !@tablename_columns[:dates].empty?
    query = "INSERT INTO us_case_#{@tablename}_history (#{@tablename_columns[:general].join(', ')} #{date_table},
              run_id, touched_run_id) VALUES (#{general_data} #{run_id}, #{run_id})"
    @client.query(query)
  end


  def insert_all_data(datas, run_id)
    date_table = ", #{@tablename_columns[:dates].join(', ')}" if !@tablename_columns[:dates].empty?
    query = "INSERT INTO us_case_#{@tablename}_history (#{@tablename_columns[:general].join(', ')} #{date_table},
              run_id, touched_run_id) VALUES "

    datas.each do |data|
      general_data = ''
      @tablename_columns[:general].each do |q|
        data[q]=@client.escape(data[q]) if data[q].instance_of? String
        general_data+=" '#{data[q]}', "
      end

      @tablename_columns[:dates].each do |q|
        if data[q]==nil
          general_data += "'0000-00-00', "
        else
          general_data += "'#{data[q]}', "
        end
      end


      query += " (#{general_data} #{run_id}, #{run_id}),"
    end
    query=query[0...-1]
    @client.query(query)
  end


  def update_run_id_for_array(md5_array)
    query = "UPDATE us_case_#{@tablename}_history SET touched_run_id=#{@current_run_id}, deleted=0
            WHERE md5_hash IN ('#{md5_array.join("', '")}') AND court_id=#{@court_id} " #
    @client.query(query)
  end

  def update_run_id_for_existing
    query = "UPDATE us_case_#{@tablename}_history SET touched_run_id=#{@current_run_id}, deleted=0
          WHERE court_id=#{@court_id} AND touched_run_id!=#{@current_run_id} AND md5_hash IN
          (SELECT md5_hash from us_case_#{@tablename} WHERE court_id=#{@court_id})"
    @client.query(query)
  end

  def select_md5(md5_array)
    query = "SELECT md5_hash FROM us_case_#{@tablename}_history WHERE md5_hash in ('#{md5_array.join("', '")}')"
    @client.query(query)
  end

  def update_deleted_rows
    query = "UPDATE us_case_#{@tablename}_history SET deleted=1 WHERE touched_run_id<>#{@current_run_id} AND court_id=#{@court_id}"
    @client.query(query)
  end

  def update_md5_in_root(case_id, columns)
    if @tablename.in?(['party','lawyer'])
      case_id_name = 'case_number'
    else
      case_id_name = 'case_id'
    end
    query = "UPDATE us_case_#{@tablename} SET md5_hash=MD5(CONCAT_WS('',#{columns.join(',')})) WHERE #{case_id_name}='#{case_id}'"
    @client.query(query)
  end


  #_______Work with data_________

  def transfer_date(days=0, limit = 1000)
    page = 0
    loop do
      md5_array = Array.new()

      root_data = Array(get_root_data(days, limit, page))
      # root_data.each_with_index do |court_case, i|
      #   md5 = PacerMD5.new(data: court_case, table: "#{@tablename}_root")
      #   md5_array.push(md5.hash)
      #   root_data[i][:md5_hash] = md5_array[-1]
      # end

      # Take array of exisiting row
      # existing_md5_hash = Array.new()
      # update_run_id_for_md5_array = Array.new()
      # select_md5(md5_array).each {|row| existing_md5_hash.push(row[:md5_hash])}

      data_for_insert = Array.new()

      root_data.each do |data|

        if data[:md5_hash]=''
          data[:activity_date]='0000-00-00' if @tablename=='activities' and (@data[:activity_date]=='' or @data[:activity_date]==nil) #TODO: delete, it existed in pacer_md5
          md5 = PacerMD5.new(data: data, table: "#{@tablename}_root")
          data[:md5_hash]=md5.hash
          update_md5_in_root(data[:case_id], md5.columns)
        end

        next if data[:md5_hash].in?(md5_array)
        md5_array.push(data[:md5_hash])

        #if !existing_md5_hash.include? data[:md5_hash] # If data is new
        data_for_insert.push(data)
        #insert_data(data, run_id=@current_run_id) # Insert new row




        #  existing_md5_hash.push(data[:md5_hash])
        #elsif existing_md5_hash.include? data[:md5_hash] # If data is in table – update run_id
        #  update_run_id_for_md5_array.push(data[:md5_hash])
        #end
      end
      #update_run_id(update_run_id_for_md5_array)
      insert_all_data(data_for_insert, run_id=@current_run_id) if !data_for_insert.empty?
      page+=1
      break if root_data.length<limit
    end
    update_deleted_rows
  end

end

# q = PutData.new('info', client_root, client_history, court_id=14)
# q.transfer_date(3, 50)

# get_root_data.each do |line|
#   line['case_filed_date']='0000-00-00' if line['case_filed_date']==nil
#   insert_data(line, make_md5(line))
#   #p line['case_filed_date']
#   #p line
# end
#insert_data.each do |q|
  #  p q
#end