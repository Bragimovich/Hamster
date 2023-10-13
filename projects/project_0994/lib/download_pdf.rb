require_relative 'aws_s3'

def connect_to_db(database=:usa_raw) #us_courts
  Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
end



class Download < Hamster::Scraper
  def initialize(limit=1000, delete = 0)
    @limit = limit
    @client = connect_to_db
    @aws_s3 = AwsS3.new()


    save_good_court
    #@aws_s3.get_files_from_s3(GOOD_COURT)
    GOOD_COURT.each {|c| delete_all_from_court(court_id=c)} if delete==1
    #get_files_from_s3

  end

  GOOD_COURT = [1, 2, 12, 35, 38]#, 48, 49]


  def save_good_court
    GOOD_COURT.each {|court_id| download_files(court_id)}
  end

  #_______DATABASE_________

  def get_pdf_links(court_id: 8, page: 0)
    offset = @limit*page
    query = "SELECT id, case_id, activity_pdf, activity_decs, activity_date FROM us_courts.us_case_activities WHERE court_id=#{court_id}
              AND activity_pdf is not null
              LIMIT #{@limit} OFFSET #{offset}" #AND Date(updated_at)> (DATE(NOW()) - INTERVAL 7 DAY)
    @client.query(query)
  end

  def get_cases_exist(activities_ids=[0])
    return [] if activities_ids.empty?
    query = "SELECT activity_id FROM us_courts.us_case_activities_pdf WHERE activity_id IN (#{activities_ids.join(', ')})"
                #AND (file!='-' or file!=null)
    @client.query(query).map { |row| row[:activity_id] }
  end

  def put_filename_to_db(key, case_data, court_id)
    query = "INSERT INTO us_courts.us_case_activities_pdf (case_id, file, activity_id, court_id) VALUES
                  ('#{case_data[:case_id]}', '#{key}', #{case_data[:id]}, #{court_id})"
    @client.query(query)
    query = "UPDATE us_courts.us_case_activities SET file='#{key}' WHERE case_id='#{case_data[:case_id]}' AND id=#{case_data[:id]}"
    @client.query(query)
  end

  def delete_all_from_court(court_id)
    @aws_s3.delete_objects(court_id)
    query = "DELETE FROM us_courts.us_case_activities_pdf WHERE court_id=#{court_id}"
    @client.query(query)
  end

  #______DOWNLOAD______

  def download_files(court_id)
    #path = "../court_pdf/#{court_id.to_s}"
    #Dir.mkdir(path) unless File.exists?(path)
    cobble = Hamster::Scraper::Dasher.new(:using=>:cobble)
    page = 0
    loop do
      result = get_pdf_links(court_id:court_id, page:page)
      activities_ids_now = result.map { |row| row[:id] }
      activities_ids_old = get_cases_exist(activities_ids_now)
      p court_id
      result.each do |row|
        next if row[:activity_pdf].nil? or row[:activity_pdf]=='-' or row[:id].in?(activities_ids_old)
        #filename = row[:activity_pdf].split('/')[-1]
        p row[:activity_pdf]
        pdf_body = cobble.get(row[:activity_pdf])
        #File.open("#{path}/#{filename}.pdf", 'wb') { |fp| fp.write(res.body) }
        if row[:activity_decs].nil?
          activity_decs = '-'
        else
          activity_decs = row[:activity_decs]
        end
        metadata = {
          court_id: court_id.to_s,
          case_id: row[:case_id],
          activity_decs: activity_decs,
          activity_date: row[:activity_date].to_s
        }
        key, url = @aws_s3.post_file_to_s3(pdf_body, metadata)
        put_filename_to_db(key, row, court_id)

      end
      break if result.to_a.length<@limit
      page+=1
    end
  end

  def down_from_url(url='')
    res = connect_to(url)
    File.open("123.pdf", 'wb') { |fp| fp.write(res.body) }
  end

end



# DOWNLOAD COURT 42
class Download_js_court
  def initialize(limit=1000)
    @limit = limit
    url = 'https://www.tncourts.gov/PublicCaseHistory/'
    @pdf_folder = "activities_pdf"
    clear_folder

    @aws_s3 = AwsS3.new()
    @client = connect_to_db
    @browser = Hamster::Scraper::Dasher.new(url, using: :hammer, hammer_opts: {headless: true, save_path: @pdf_folder}).smash
    looping
    @browser.quit
  end

  COURT_ID=42

  def clear_folder
    Dir["./#{@pdf_folder}"].each do |filename|
      path_to_file = "./#{@pdf_folder}/#{filename}"
      File.delete(path_to_file) if File.exist?(path_to_file)
    end
  end

  #_________________DATABASE_____________
  def get_links(page=0)
    offset = @limit*page
    query = "SELECT id, case_id, data_source_url FROM us_courts.us_case_activities WHERE court_id=#{COURT_ID}
              LIMIT #{@limit} OFFSET #{offset}"
    @client.query(query)
  end

  def get_activity_id(case_id, activity_decs, activity_date_not_good=nil)
    query = "SELECT id, case_id, activity_pdf, activity_date, activity_decs FROM us_case_activities
              WHERE activity_decs='#{activity_decs}' and case_id='#{case_id}' "

    if !activity_date_not_good.nil?
      activity_date ="#{activity_date_not_good.split('/')[-1]}-#{activity_date_not_good.split('/')[0]}-#{activity_date_not_good.split('/')[1]}"
      query += "AND activity_date='#{activity_date}'"
    end

    @client.query(query).first
  end

  def put_filename_to_db(key, case_data, court_id)
    query = "INSERT INTO us_courts.us_case_activities_pdf (case_id, file, activity_id, court_id, pdf_in_case) VALUES
                  ('#{case_data[:case_id]}', '#{key}', #{case_data[:id]}, #{court_id}, #{case_data[:pdf_in_case]})"
    @client.query(query)
    query = "UPDATE us_courts.us_case_activities SET file='#{key}', activity_pdf='https://court-cases-activities.s3.amazonaws.com/#{key}'
                 WHERE case_id='#{case_data[:case_id]}' AND id=#{case_data[:id]}"
    @client.query(query)
    # query = "UPDATE usa_raw.us_case_activities SET activity_pdf='https://court-cases-activities.s3.amazonaws.com/#{key}'
    #              WHERE case_id='#{case_data[:case_id]}' AND id=#{case_data[:id]}"
    # @client.query(query)
  end

  def get_cases_exist(case_ids=[0])
    case_id_array = case_ids.join("', '")
    query = "SELECT case_id, pdf_in_case, count(*) as pdf_in_db FROM us_courts.us_case_activities_pdf WHERE case_id IN ('#{case_id_array}') GROUP BY case_id
                AND (file!='-' or file!=null) and court_id=#{COURT_ID}"
    result = @client.query(query)
    result_hash = {}

    result.map {|row| result_hash[row[:case_id].to_s]={:pdf_in_case=>row[:pdf_in_case], :pdf_in_db=>row[:pdf_in_db] }}
    result_hash

    # result.map { |row| result_hash[row[:case_id]]=row[:pdf_in_case] }
    # result_hash
  end

  def delete_case_id(case_id)
    @aws_s3.delete_specific_files(COURT_ID, case_id)
    query = "DELETE FROM us_courts.us_case_activities_pdf WHERE case_id='#{case_id}' AND court_id=#{COURT_ID}"
    @client.query(query)
  end


  #__________DOWNLOADING_____________

  def looping
    page=0
    loop do
      result = get_links(page)

      case_ids_now = result.map { |row| row[:case_id] }
      existing_case_ids = get_cases_exist(case_ids_now)
      existing_case_ids.each do |case_id, pdf_numbers|
        if pdf_numbers[:pdf_in_case]!=pdf_numbers[:pdf_in_db]
          delete_case_id(case_id)
          existing_case_ids.delete(case_id)
        end
      end

      result.each do |row|
        next if row[:data_source_url].nil? or row[:data_source_url]=='-' or row[:case_id].in?(existing_case_ids.keys)
        begin
          get_js_court(row)
          existing_case_ids[row[:case_id]]={}
        rescue => e
          puts e
          delete_case_id(row[:case_id])
        end
        sleep 2
      end
      break if result.to_a.length<@limit
      page+=1
    end
  end

  def get_js_court(row)
    url = row[:data_source_url]
    case_id = row[:case_id]

    @browser.go_to(url)
    doc = Nokogiri::HTML(@browser.body)

    metadata = {
      court_id: COURT_ID.to_s,
      case_id: case_id#row[:case_id]
    }

    pdf_in_case = doc.css(".pdf").to_a.length - 2

    doc.css("[@id='case-history']").css("tr")[1..].each_with_index do |tr, i|
      td = tr.css("td")
      if td[3].content.strip!=''
        activity = get_activity_id(case_id, td[1].content, td[0].content)
        metadata[:activity_decs] = activity[:activity_decs]
        metadata[:activity_date] = activity[:activity_date].to_s
        activity[:pdf_in_case] = pdf_in_case

        (0...td[3].content.strip.scan("PDF").size).each do |pdf_n|
          js_code = "javascript:__doPostBack('ListView10$ctrl#{i}$ListView12$ctrl#{pdf_n}$LinkButton1','')"
          @browser.go_to(js_code)
          sleep 1

        end
        r = 0
        Dir.entries("./#{@pdf_folder}").each do |filename|
          path_to_file = "./#{@pdf_folder}/#{filename}"
          if path_to_file.match(/.crdownload$/) and File.exist?(path_to_file)
            r+=1
            sleep 1
            redo if r<4
            File.delete(path_to_file)
          elsif path_to_file.match(/.crdownload$/) and !File.exist?(path_to_file)
            new_filename = filename.split(/.crdownload$/)[0]
            filename =  new_filename if !File.exist?("./#{@pdf_folder}/#{new_filename}")
          end
          next if !filename.match(/.pdf$/)

          File.open(path_to_file, 'rb') do |file|
            key, url = @aws_s3.post_file_to_s3(file, metadata)
            put_filename_to_db(key, activity, COURT_ID)
          end
          File.delete(path_to_file) if File.exist?(path_to_file)
        end

      end
      #@aws_s3.get_files_from_s3
    end
  end

end




class Court_30 < Hamster::Scraper
  def initialize
    p 'start'
    get_file
  end

  def get_file(url_pdf='https://appellatepublic.kycourts.net/api/api/v1/publicaccessdocuments/446c08770c067f1f15011b127f86050e9d6da9db015a0ecb16bb64aa01faea72/download')
    proxy = 'socks://iHtfgW31135:hgZxWDvOhE@102.129.207.74:4294'
    #socks5 = "socks://noihtpkm-dest:h4kbu0kn5ruo@45.72.97.42:7595"
    url = 'https://appellatepublic.kycourts.net/documents/446c08770c067f1f15011b127f86050e9d6da9db015a0ecb16bb64aa01faea72/download'
    # first_site = connect_to(url:url, open_timeout:10, proxy:proxy)
    # p first_site.headers
    # cookies_array = first_site.headers["set-cookie"].split(';')[0].split('=')
    # cookies = {cookies_array[0]=>cookies_array[1]}
    # p cookies
    # q = connect_to(url:url_pdf, headers: first_site.headers, cookies:cookies, open_timeout:10, proxy:proxy)
    #url2='https://appellatepublic.kycourts.net/api/api/v1/publicaccessdocuments/446c08770c067f1f15011b127f86050e9d6da9db015a0ecb16bb64aa01faea72/download'

    #login = 'noihtpkm-dest'
    #pass = 'h4kbu0kn5ruo'
    #proxy = {scheme: 'socks5', host: '45.72.97.42', port:7595, username: login, password: pass }
    #browser = Ferrum::Browser.new({headless: false})
    browser = Hamster::Scraper::Dasher.new('http://google.com/', using: :hammer, hammer_opts: {headless: false}).smash
    browser.go_to(url)
    sleep 10
    browser.go_to(url_pdf)
    #p browser.body
    #browser.go_to('https://ctrack.sccourts.org/public/caseView.do?csIID=32382')
    #sleep 15
    #browser.go_to(url)
    sleep 5
    #browser.quit
    # agent = Mechanize.new
    # q = agent.get('https://ctrack.sccourts.org/public/caseView.do?csIID=32382')
    # sleep 5
    # q = agent.get(url)
    #p ' !!'
    #p q.body
    #p q.headers
    #sleep 5
    p browser.body
    #File.open("301.html", 'wb') { |fp| fp.write(browser.body) }
  end
end