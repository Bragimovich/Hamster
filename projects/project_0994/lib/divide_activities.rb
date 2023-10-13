

def connect_to_db(database=:usa_raw) #us_court_cases
  Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
end


class DivideActivities < Hamster::Scraper
  def initialize(court_id = 25, limit=10, delete = 0)
    @limit = limit
    @client = connect_to_db
    @court_id = court_id
    start_with_courts
  end


  #_______DATABASE______
  #

  def get_courts
    query = "SELECT court_id FROM us_courts_table"
    @client.query(query).map {|row| row[:court_id]}
  end

  def get_activities(court_id, page=0)
    offset = page * @limit
    query = "SELECT id, case_id, activity_decs FROM us_case_activities WHERE court_id=#{court_id} LIMIT #{@limit} OFFSET #{offset}"
    @client.query(query)
  end

  def insert_activity_decs(data)
    query = "INSERT INTO us_case_activity_decs (case_id, activity_decs, decs_title, decs_date, activity_id) VALUES"
    data.each do |row|
      query += " ('#{row[:case_id]}', '#{@client.escape(row[:activity_decs])}', '#{@client.escape(row[:decs_title])}',
                   '#{row[:decs_date]}', #{row[:id]}),"
    end
    query = query[0...-1]
    @client.query(query)
  end

  def existed_activities(activities_ids)
    query = "SELECT activity_id FROM us_case_activity_decs WHERE activity_id in (#{activities_ids.join(',')})"
    @client.query(query).map {|row| row[:activity_id]}
  end


  #________WORK WITH DATA_________
  #

  def start_with_courts
    get_courts.each do |court_id|
      p court_id
      activity_decs_transform(court_id)
    end
  end


  def activity_decs_transform(court_id)
    page = 0

    loop do
      activities =  get_activities(court_id, page)

      activities_ids = activities.map { |row| row[:id] }

      existed_id = existed_activities(activities_ids)  if !activities_ids.empty?
      activity_decs = []

      activities.each do |activity|
        next if activity[:id].in?(existed_id)
        activity_decs.push(activity
          #{case_id: activity[:case_id], activity_decs: activity[:activity_decs][0...1999], id:activity[:id]}
        )
        decs_title, decs_date = divide_string(activity[:activity_decs])
        activity_decs[-1][:decs_title] = decs_title
        activity_decs[-1][:decs_date] = decs_date
      end

      insert_activity_decs(activity_decs) if !activity_decs.empty?
      break if activities.to_a.length<@limit
      page+=1
    end


  end

  def divide_string(text='')
    decs_title=/(^([A-Z]{2,}(\W|$))*)/.match(text.strip).to_s
    decs_date = /(\d*\/\d*\/\d*)|(\d+\-\d+\-\d+)/.match(text).to_s
    return decs_title,decs_date
  end

  def divide_string_test(text='')
    # text=['CERTIORARI - Petition for WRIT of Certiorari', 'Discretionary Application', 'HABEAS CORPUS - Habeas Corpus Notice of Appeal',
    #       'CIVIL ACTION NO. 4:18-cv-268-HLM 385 28:1332 Case Initiating Documents-Notice of Removal, Keith Bien vs. Tucker Milling, LLC. Filing fee $ 400, receipt number 113E-8316935. (Attachments: # 1 Exhibit EXHIBIT A Pleadings, # 2 Exhibit EXHIBIT B - PRE SUIT DEMAND, # 3 Exhibit NOTICE OF FILING, # 4 Civil Cover Sheet)(McLaughlin, Matthew) Modified on 12/10/2018 (bjh). (Entered: 12/07/2018)', 'ORAL ARGUMENT ORAL - Appellant Request for Oral Argument',
    #       ' MOTION to Dismiss Citations 6225265, 6225266 and 6225267  by USA as to Charles E. Galloway. (Tarvin, Lisa) (Entered: 08/30/2018)',
    #       'MIVIL ACTION 4:18-cv-268-HL as to Charles E. Galloway. (Tarvin, Lisa) (Entered: 08/30/2018) AND 30-02-2021',
    #       'fdfd 333-2-4', 'JUDGMENT / ORIGINAL ACTION DATE'
    # ]
    #rex = '(^[A-Z]{2,} )||(^[A-Z]{2,} [A-Z]{2,}) '
    #

    text.each do |t|
      p '____'
      p t
      upper_string=/(^([A-Z]{2,}(\W|$))*)/.match(t.strip) # Take upper cases word
      p upper_string.to_s

      dates = /(\d*\/\d*\/\d*)|(\d+\-\d+\-\d+)/.match(t)
      p dates.to_s
      p '!!!'

    end

  end


end