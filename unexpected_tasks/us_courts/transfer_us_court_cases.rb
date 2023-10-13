# frozen_string_literal: true

require_relative 'transfer_cases/us_cases'
require_relative 'transfer_cases/transfer_run_id'


module UnexpectedTasks
  module UsCourts
    class TransferUsCourtCases
      def self.run(**options)
        limit = options[:limit] || 0
        days = options[:days] || 0
        continue = options[:continue] || 0
        p 'hi'
        start_transfer(limit, days, continue)
      end
    end
  end
end

def connect_to_db(database=:us_court_cases) #us_court_cases
  Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
end


def start_transfer(limit, days, continue)


  client_dev = connect_to_db( :us_court_cases)
  query = "SELECT court_id, court_name_id, court_name, created_by FROM us_courts_start WHERE not_test=1"
  statement = client_dev.prepare(query)
  result = statement.execute
  result.each do |court|
    client_dev = connect_to_db( :us_court_cases)
    client_root_us_courts = connect_to_db( :us_courts)
    client_root_usa_raw = connect_to_db( :usa_raw)
    clients = {:dev =>client_dev, :root_usa_raw => client_root_usa_raw, :root_us_courts =>client_root_us_courts}
    puts "Start transfer #{court[:court_name]} ..."
    c = TransferData.new(clients, court = court, limit = limit, day_in_past=days, continue)
    puts 'transfer info table'
    c.transfer_to_root(type=:info)
    puts 'transfer pdf on aws table'
    c.transfer_to_root(type=:pdfs_on_aws)
    puts 'transfer party table'
    c.transfer_to_root(type=:party)
    puts 'transfer activities table'
    c.transfer_to_root(type=:activities)
    puts 'transfer judgement table'
    c.transfer_to_root(type=:judgment)
    puts 'transfer relations_activity table'
    c.relations()
    puts 'Transfer for court was ended \n'
  end
end


class TransferData

  # Code to transfer data from dev table to root
  # client = connect_to_db(database=:us_court_cases)
  # transfer = TransferData.new(client, 25)
  # transfer.transfer_to_root(type=:info) #types = [:info, :party, :activities]

  def initialize(clients, court, limit=5, day_in_past=1, continue=0)
    @clients = clients
    court_name_id = court[:court_name_id]

    @tablename = {:dev => check_nonexistent_tables(court_name_id, make_table_names(court_name_id)),
                  :root_usa_raw => make_table_names('us'),
                  :root_us_courts => make_table_names('us')}

    @tablename[:root_usa_raw][:court] = @tablename[:root_usa_raw][:court]+'_table'
    @tablename[:root_us_courts][:court] = @tablename[:root_us_courts][:court]+'_table'
    @limit = limit

    @court = get_court(court[:court_id])
    @court.delete(:data_source_url)
    @court[:scrape_dev_name] = court[:created_by]
    @day_in_past = day_in_past
    @continue = continue
  end



  COLUMNS = {
    :info =>{
      :root_usa_raw =>%w[court_name court_state court_type court_id
            case_name case_id case_description case_type disposition_or_status
              status_as_of_date judge_name scrape_dev_name data_source_url scrape_frequency],
      :root_us_courts => %w[court_id case_name case_filed_date case_id case_description case_type disposition_or_status
             status_as_of_date judge_name data_source_url created_by md5_hash run_id touched_run_id],
      :dates => %w[case_filed_date],
      #:int => %w[pl_gather_task_id],
      :dev => %w[court_id case_name case_filed_date case_id case_description case_type disposition_or_status
             status_as_of_date judge_name data_source_url created_by md5_hash]
    },
    :court =>{
      :root_usa_raw =>
        %w[court_id court_name court_state court_type court_sub_type scrape_dev_name data_source_url], #pl_gather_task_id
      :root_us_courts =>
        %w[court_id court_name court_state court_type court_sub_type created_by data_source_url],
      :dates =>[],
      :dev =>
            %w[id court_name court_state court_type court_sub_type created_by data_source_url md5_hash]
    },
    :party => {
      :root_usa_raw =>
        %w[court_id case_number party_name party_type party_address party_city party_state party_zip data_source_url scrape_dev_name is_lawyer party_description scrape_frequency],
      #pl_gather_task_id  law_firm is_lawyer
      :root_us_courts =>
        %w[court_id case_id party_name party_type party_address party_city party_state party_zip party_law_firm created_by
            data_source_url md5_hash is_lawyer party_description scrape_frequency run_id touched_run_id],
      :dates =>[],
      :dev => # law_firm
        %w[court_id case_id party_name party_type party_address party_city party_state party_zip law_firm created_by data_source_url md5_hash is_lawyer party_description]
    },
    :activities => {
      :root_usa_raw =>
        %w[court_id case_id activity_decs activity_type activity_pdf scrape_dev_name data_source_url scrape_frequency pl_gather_task_id], #pl_gather_task_id
      :root_us_courts =>
        %w[court_id case_id activity_date activity_decs activity_pdf created_by data_source_url md5_hash
         pl_gather_task_id run_id touched_run_id created_by md5_hash],
      :dates => %w[activity_date],
      :dev =>
        %w[court_id case_id activity_date activity_decs activity_pdf created_by data_source_url md5_hash] # activity_type
    },
    :complaint => {
      :root_us_courts => %w[court_id case_id party_name type filed_date requested_amount status description
                          data_source_url created_by md5_hash run_id touched_run_id],
      :dev  => %w[court_id case_id party_name type filed_date requested_amount status description
                    data_source_url created_by md5_hash run_id touched_run_id]
    },
    :judgment => {
      :root_us_courts => %w[court_id case_id complaint_id party_name fee_amount judgment_amount md5_hash
                        data_source_url created_by md5_hash run_id touched_run_id],
      :dev  => %w[court_id case_id complaint_id party_name fee_amount judgment_amount judgment_date
                  data_source_url created_by md5_hash],
      :dates => %w[judgment_date],
    },
    :pdfs_on_aws => {
      :root_us_courts => %w[court_id case_id source_type aws_link source_link md5_hash],
      :dev => %w[court_id case_id source_type aws_link source_link md5_hash],
      :dates =>[],
    },
    :relations_info_pdf => {
      :root_us_courts => %w[case_info_md5 case_pdf_on_aws_md5 created_by],
      :dev => %w[case_info_md5 case_pdf_on_aws_md5 created_by],
      :dates =>[],
    },
    :relations_activities_pdf => {
      :root_us_courts => %w[case_activity_md5 case_pdf_on_aws_md5 created_by],
      :dev => %w[case_activity_md5 case_pdf_on_aws_md5 created_by],
      :dates =>[],
    },

  }

  CHECK_COLUMNS = {
    :info => [:disposition_or_status, :judge_name, :data_source_url, :case_description, :status_as_of_date, :case_type, :case_name, ],
    :party => [:party_name, :party_type, :data_source_url, :party_address, :party_city, :party_description, :party_law_firm, :party_zip, :party_state, ],
    :activities => [:data_source_url, :activity_decs, :activity_type, :activity_pdf, :file],
    :complaint => [:party_name, :type, :filed_date, :requested_amount, :status, :description],
    :judgment => [:party_name, :fee_amount, :judgment_amount],
    :pdfs_on_aws => [],
    :relations_info_pdf => [],
    :relations_activities_pdf => [],

    # :info => %w[disposition_or_status judge_name data_source_url case_description status_as_of_date case_type case_name],
    # :party => %w[party_name party_type data_source_url party_address party_city party_description party_law_firm party_zip party_state],
    # :activities => %w[data_source_url activity_decs activity_type activity_pdf file],
  }

  ANALOGUES = {
    :court => {
      #'id' => 'court_id',
      #'created_by' => 'scrape_dev_name',
    },
    :info => {
      #'id' => 'court_id',
      #:created_by => :scrape_dev_name,
    },
    :activities => {
      #:created_by => :scrape_dev_name
    },
    :party => {
      :law_firm => :party_law_firm,
      #:case_id => :case_number,
      #:created_by => :scrape_dev_name
    },
    :judgment => {},
    :relations_activities_pdf =>{},
  }

  TABLE_NAME = {
    :court => "_courts",
    :info => "_case_info",
    :lawyer => "_case_lawyer",
    :party => "_case_party",
    :activities => "_case_activities",
    :complaint => "_case_complaint",
    :judgment => "_case_judgment",
    :pdfs_on_aws => "_case_pdfs_on_aws",
  }

  def make_table_names(court_name)
    {
      :court => "#{court_name}_courts",
      :info => "#{court_name}_case_info",
      :lawyer => "#{court_name}_case_lawyer",
      :party => "#{court_name}_case_party",
      :activities => "#{court_name}_case_activities",
      :complaint => "#{court_name}_case_complaint",
      :judgment => "#{court_name}_case_judgment",
      :pdfs_on_aws => "#{court_name}_case_pdfs_on_aws",
      :relations_info_pdf => "#{court_name}_case_relations_info_pdf",
      :relations_activities_pdf => "#{court_name}_case_relations_activities_pdf"
    }
  end

  def check_nonexistent_tables(court_name, table_names_hash)
    court_tables_in_db = existed_court_table(court_name)
    table_names_hash.each do |table_key, table_name|
      next if table_name.in?(court_tables_in_db)
      table_names_hash.delete(table_key)
    end
    table_names_hash
  end

  def existed_court_table(court_name)
    query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'us_court_cases' AND table_name like '#{court_name}_%'; "
    statement = @clients[:dev].prepare(query)
    result = statement.execute
    result.map { |row| row[:table_name] }
  end


  #____________COURT__________


  # method for check and select columns in court tables
  # court_where [hash] – {'court_name': STR, 'court_id': INT}
  # (key must be ColumNname in table[:type])
  def select_court(table, type=:dev, court_where=nil)
    query = "SELECT #{COLUMNS[table][type].join(', ')} FROM #{@tablename[type][table]} "
    query += "WHERE #{court_where.keys[0]}='#{court_where.values[0]}'" if court_where
    statement = @clients[type].prepare(query)
    result = statement.execute
    result.first
  end


  def insert_new_court(data)
    good_data = Hash.new()
    COLUMNS[:court][:root_us_courts].each do |columnname|
      columnname = columnname.to_sym
      if data.keys.include?(columnname)
        good_data[columnname]=data[columnname]
      end
    end
    query = "INSERT INTO #{@tablename[:root_us_courts][:court]} (#{good_data.keys.join(', ')}) VALUES
        ('#{good_data.values.join("', '")}')"

    @clients[:root_us_courts].query(query)
  end

  def get_court(court_id)
    court_data_root = select_court(table=:court, type=:root_us_courts, court_where={'court_id' => court_id})
    return court_data_root if court_data_root

    # У всех в своих таблицах должен быть правильный court_id по таблице
    # https://docs.google.com/spreadsheets/d/1K1cqLFZyDyaW6YXO1j7hNO65ZbHU6C0YLoyWN77shzo/edit#gid=0
    court_data_dev = select_court(table=:court, type=:dev)
    if court_data_dev
      ANALOGUES[:court].each do |dev_key, root_key|
        court_data_dev[root_key.to_sym] = court_data_dev[dev_key.to_sym]
        court_data_dev.delete(dev_key.to_sym)
      end
    end
    court_data_dev[:court_id] = court_id
    insert_new_court(court_data_dev) if court_data_dev
    select_court(table=:court, type=:root_us_courts, court_where={'court_id' => court_id})

  end

  #__________PUT DATA_______

  def get_data_dev(table, page = 0)
    query = "SELECT #{COLUMNS[table][:dev].join(', ')}
                FROM #{@tablename[:dev][table]} WHERE court_id=#{@court[:court_id]} AND deleted=0 "
    query += "And Date(updated_at)>CURDATE()-#{@day_in_past} "  if @day_in_past>0
    offset = page * @limit
    query += "LIMIT #{@limit} OFFSET #{offset}" if @limit>0
    p query
    @clients[:dev].query(query)
  end


  # def delete_deleted(table, day_in_past=1)
  #   query = "DELETE FROM usa_raw.#{@tablename[:root][table]} where md5_hash in
  #     (SELECT md5_hash FROM us_courts.#{@tablename[:dev][table]} WHERE deleted = 1 "
  #   query += "And Date(updated_at)>CURDATE()-#{day_in_past}"  if day_in_past >0
  #   query += ')'
  #   @clients[:dev].query(query)
  # end

  def mark_deleted(table)
    query = "UPDATE us_courts.#{@tablename[:root_us_courts][table]} SET deleted=1 WHERE md5_hash in
      (SELECT md5_hash FROM us_courts.#{@tablename[:dev][table]} WHERE deleted = 1 "
    query += "And Date(updated_at)>CURDATE()-#{@day_in_past}"  if @day_in_past >0
    query += ')'
    @clients[:dev].query(query)
  end

  def insert_data_to_root(table=:info, data_dev)
    datas = Hash.new()

    if table==:activities && !data_dev[:activity_pdf].nil? # TODO: delete thing
      if data_dev[:activity_pdf].length>450
        data_dev[:activity_pdf] = data_dev[:activity_pdf].split(',')[0]
        data_dev[:activity_pdf] = nil if data_dev[:activity_pdf].length>500
      end
    end

    (COLUMNS[table][:root_us_courts]+COLUMNS[table][:dates]).each do |key|
      if COLUMNS[table][:dates].include?(key) #if date: transform to date
        next if data_dev[key.to_sym].nil?
        if data_dev[key.to_sym].class==Date || data_dev[key.to_sym].class==DateTime || data_dev[key.to_sym].class==Time
          datas[key.to_sym] = data_dev[key.to_sym]
          next
        end
        # if data_dev[key.to_sym].match(/\d{2}\/\d{2}\/\d{2-4}/)
        # elsif data_dev[key.to_sym].match(/\d{2-4}-\d{2}-\d{2}/)
        if data_dev[key.to_sym].match(/\d{2}\/\d{2}\/\d{2-4}/)
          datas[key.to_sym]=Date.strptime(data_dev[key.to_sym].strip, '%m/%d/%Y')
        elsif data_dev[key.to_sym].match(/\d{2-4}-\d{2}-\d{2}/)
          datas[key.to_sym]=Date.strptime(data_dev[key.to_sym].strip, '%Y-%m-%d')
        else
          datas[key.to_sym] = data_dev[key.to_sym]
        end
      elsif COLUMNS[table][:root_us_courts].include?(key) #if key in columnnames: add to data for INSERT
        datas[key.to_sym] = data_dev[key.to_sym]
      #elsif COLUMNS[table][:int].include?(key)
        #  datas[key] = data_dev[key.to_sym].to_i
      end
    end

    CHECK_COLUMNS[table].each do |column|
      unless check_row(datas[column])
        datas[column] = nil
      end
    end
    db_root_model(table).insert(datas)
  end


  def insert_data_to_root_old(table=:info, data_dev)
    datas = Hash.new()


    (COLUMNS[table][:root_us_courts]+COLUMNS[table][:dates]).each do |key|
      if COLUMNS[table][:dates].include?(key) #if date: transform to date
        begin
          datas[key.to_sym]=Date.strptime(data_dev[key.to_sym].strip, '%m/%d/%Y')
        rescue
          datas[key.to_sym]=Date.strptime(data_dev[key.to_sym].strip, '%Y-%m-%d')
        end
      elsif COLUMNS[table][:root_us_courts].include?(key) #if key in columnnames: add to data for INSERT
        datas[key.to_sym] = data_dev[key.to_sym]
        #elsif COLUMNS[table][:int].include?(key)
        #  datas[key] = data_dev[key.to_sym].to_i
      end
    end

    CHECK_COLUMNS[table].each do |column|
      unless check_row(datas[column])
        datas[column] = nil
      end
    end

    query = "INSERT INTO #{@tablename[:root_us_courts][table]} (#{datas.keys.join(', ')}) VALUES "
    datas = datas.each { |key, value| datas[key] = @clients[:root_us_courts].escape(value) if value.instance_of? String }
    query += "('#{datas.values.join("', '")}')"
    @clients[:root_us_courts].query(query)
  end


  def check_row(row)
    return if row.nil?
    bad_rows = ['', '-', 'null', 'non', 'none', 'nil', '\n', 'unspecified', '^M']
    !row.downcase.in?(bad_rows)
  end

  def select_data_from_root(table=:info, case_id)
    root_columns = COLUMNS[table][:root_us_courts]
    root_columns += COLUMNS[table][:dates] if !COLUMNS[table][:dates].nil?
    query = "SELECT #{root_columns.join(', ')} FROM #{@tablename[:root_us_courts][table]} "
    case_id_key = 'case_id'
    case_id_key = ANALOGUES[table][:case_id] if ANALOGUES[table].keys.include?(:case_id) if !ANALOGUES[table].nil?
    query += "WHERE #{case_id_key}='#{case_id}'"
    p query
    statement = @clients[:root_us_courts].prepare(query)
    result = statement.execute
    result
  end

  def select_data_from_root_new(table=:info, case_ids)
    root_columns = COLUMNS[table][:root_us_courts]
    root_columns += COLUMNS[table][:dates] if !COLUMNS[table][:dates].nil?
    query = "SELECT #{root_columns.join(', ')} FROM #{@tablename[:root_us_courts][table]} "
    case_id_key = 'case_id'
    case_id_key = ANALOGUES[table][:case_id] if ANALOGUES[table].keys.include?(:case_id) if !ANALOGUES[table].nil?
    query += "WHERE #{case_id_key} in ('#{case_ids.join("', '")}')"
    statement = @clients[:root_us_courts].prepare(query)
    result = statement.execute
    result
  end

  def update_run_id(table, md5_existed, run_id)
    query = "UPDATE #{@tablename[:root_us_courts][table]} SET deleted = 0, touched_run_id = #{run_id} WHERE md5_hash in ('#{md5_existed.join("', '")}')"
    @clients[:root_us_courts].query(query)
    # if @day_in_past >0
    #   query = "UPDATE #{@tablename[:root_us_courts][table]} SET touched_run_id = #{run_id} WHERE court_id=#{@court[:court_id]}"
    #   query += "AND Date(updated_at)>CURDATE()-#{@day_in_past}"
    #   @clients[:root_us_courts].query(query)
    # end
  end

  def transfer_to_root(table=:info)
    #mark_deleted(table)
    if !table.in?(@tablename[:dev].keys)
      p "Table for #{table} doesn't exist!"
      return
    end

    page = 0

    file_name_last_page = "../#{table}_page"
    p table
    if @continue == 1 and table!='judgment'

      court_id, page_from_file, limit_from_file = File.open(file_name_last_page, "r") { |f| f.read.split(':').map { |i| i.to_i } }

      if court_id == @court[:court_id]
        page = page_from_file
        @limit = limit_from_file
      end
    end

    #md5  = MD5Hash.new(table: table.to_sym)

    run_id_object = TransferRunId.new(table)
    run_id = run_id_object.run_id
    file = File.open("logs_transfer", "a")


    loop do

      data_dev = get_data_dev(table, page)

      case_ids = data_dev.map { |row| row[:case_id] }
      md5_existed = []
      if !case_ids.empty?
        root_data = select_data_from_root_new(table = table, case_id = case_ids)
        root_data.each do |root_data_raw|
          md5_existed.push(root_data_raw[:md5_hash])
        end
      end
      new_data = 0
      data_dev.each do |dev_data_raw|
        next if md5_existed.include?(dev_data_raw[:md5_hash])
        #court = select_court(:court, court_where={'court_id'=>dev_data_raw['court_id']})
        #dev_data_raw = dev_data_raw.merge(@court)
        if !ANALOGUES[table].nil?
          ANALOGUES[table].each do |dev_key, root_key|
            dev_data_raw[root_key]=dev_data_raw[dev_key]
            #dev_data_raw.delete(dev_key)
          end
        end


        begin
          #dev_data_raw[:md5_hash] = md5.generate(dev_data_raw)
          # next if md5_existed.include?(dev_data_raw[:md5_hash])
            dev_data_raw[:run_id] = run_id
            dev_data_raw[:touched_run_id] = run_id

            #dev_data_raw[:last_scrape_date] = Date.today()
            #dev_data_raw[:next_scrape_date] = Date.today()+1
            #dev_data_raw[:expected_scrape_frequency] = dev_data_raw[:scrape_frequency]
            insert_data_to_root(table, dev_data_raw)
            new_data=new_data+1
        rescue => error
            p error
            file.write(error.to_s+"\n")
        end
      end
      p "New rows added #{new_data}"

      File.open(file_name_last_page, "w") { |f| f.write "#{@court[:court_id]}:#{page}:#{@limit}" }
      page = page+1
      update_run_id(table, md5_existed, run_id) if !md5_existed.empty?
      break if data_dev.to_a.length<@limit
    end

    file.close
    run_id_object.finish if table.in?([:judgment, :complaint])
  end

  def transfer_additional_tables(type, md5_hash_original)
    column_original_name = COLUMNS[type]

    used_rows = DB_MODEL[type].where(column_original_name => md5_hash_original)

    md5_hash_complaint = used_rows.map { |row| row.case_complaint_md5 }

    check
    begin
      insert_data_to_root(table, md5_hash_complaint)
    rescue => error
      p error
      file.write(error.to_s+"\n")
    end

  end

  def relations
    if !@tablename[:dev][:relations_activities_pdf].nil?
      query = "INSERT IGNORE INTO us_courts.us_case_relations_activities_pdf (case_activities_md5, case_pdf_on_aws_md5)
        SELECT case_activity_md5, case_pdf_on_aws_md5 FROM #{@tablename[:dev][:relations_activities_pdf]};"
      @clients[:dev].query(query)
    end
    # if !@tablename[:dev][:relations_info_pdf].nil?
    #   query = "INSERT IGNORE INTO us_courts.us_case_relations_info_pdf (case_info_md5, case_pdf_on_aws_md5)
    #     SELECT case_info_md5, case_pdf_on_aws_md5 FROM #{@tablename[:dev][:relations_info_pdf]};"
    #   @clients[:dev].query(query)
    # end
  end


end
