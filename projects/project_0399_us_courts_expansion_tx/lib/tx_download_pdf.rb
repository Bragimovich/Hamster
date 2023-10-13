def connect_to_db(database = :us_court_cases)
  #us_courts
  Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
end

class TXDownload < Hamster::Scraper
  def initialize(limit = 10, delete = 0)
    @limit = limit
    @client = connect_to_db
    @s3 = AwsS3.new(bucket_key = :us_court)
    @base_url = 'http://appellateinquiry.jud.ct.gov/'
    @semaphore = Mutex.new
    @run_id = CtSaacCaseRuns.last.id
  end

  #_______DATABASE_________
  def get_pdf_links(page: 0)
    offset = @limit * page
    query = "SELECT id, case_id, file, activity_desc, activity_date, md5_hash, court_id FROM us_court_cases.tx_saac_case_activities WHERE
              file is not null AND file != '' AND file NOT LIKE 'CaseDetail.aspx?CRN=%' AND activity_pdf IS NULL
              LIMIT #{@limit} OFFSET #{offset};"
    @client.query(query).to_a
  end

  def get_pdf_exist(client, case_id, source_link)
    query = "SELECT * FROM us_court_cases.tx_saac_case_pdfs_on_aws
                WHERE case_id = '#{case_id}'
                AND source_link = '#{source_link}'"
    result = client.query(query).to_a

    if result.size > 0
      true
    else
      false
    end
  end

  def put_filename_to_db(client, case_data, court_id, aws_lnk, md5_hash)
    # tx_saac_case_pdfs_on_aws
    query = "INSERT INTO us_court_cases.tx_saac_case_pdfs_on_aws (court_id, case_id, source_type, aws_link, source_link, md5_hash)
             VALUES (#{court_id}, '#{case_data[:case_id]}', 'activity', '#{aws_lnk}', '#{case_data[:file]}', '#{md5_hash}')"
    client.query(query)

    # tx_saac_case_relations_activity_pdf
    query = "INSERT INTO us_court_cases.tx_saac_case_relations_activity_pdf (case_activities_md5, case_pdf_on_aws_md5)
             VALUES ('#{case_data[:md5_hash]}', '#{md5_hash}')"
    client.query(query)

    # tx_saac_case_activities
    query = "UPDATE us_court_cases.tx_saac_case_activities SET activity_pdf = 'uploaded'
             WHERE id = #{case_data[:id]}"
    client.query(query)
  end

  #______DOWNLOAD______
  def download_files
    begin
      cobble = Hamster::Scraper::Dasher.new(:using => :cobble)
      page = 0

      loop do
        page += 1
        result = get_pdf_links(page: page)
        result_size = result.size

        threads_links = Array.new(10) do
          Thread.new do
            client_1 = connect_to_db
            aws_s3 = AwsS3.new(bucket_key = :us_court)
            loop do
              break if result.size == 0

              row = nil

              @semaphore.synchronize do
                row = result.pop
              end
              break if row.nil?

              next if row[:file].nil? or row[:file] == '-'
              next if get_pdf_exist(client_1, row[:case_id], row[:file])

              pdf_body = cobble.get(row[:file])

              if row[:activity_desc].nil?
                activity_desc = '-'
              else
                activity_desc = row[:activity_desc]
              end
              metadata = {
                court_id: row[:court_id].to_s,
                case_id: row[:case_id],
                activity_desc: activity_desc,
                activity_date: row[:activity_date].to_s
              }

              # us_courts_expansion_<court_id>_<case_id>_<file_name>
              key = "us_courts_expansion/#{metadata[:court_id]}/#{metadata[:case_id]}/#{row[:file].gsub('https://search.txcourts.gov/SearchMedia.aspx?MediaVersionID=', '')}"

              url = aws_s3.put_file(pdf_body, key, metadata)

              md5_hash = {
                court_id: row[:court_id].to_s,
                case_id: row[:case_id],
                aws_link: url,
                source_link: @base_url + row[:file]
              }

              cols = %i[court_id case_id aws_link source_link]
              md5 = MD5Hash.new(:columns => cols)
              md5.generate(md5_hash)

              put_filename_to_db(client_1, row, row[:court_id], url, md5.hash)
            end
            client_1.close
          end
        end
        threads_links.each(&:join)

        break if result_size < @limit
      end

      Hamster.report(to: 'Dmitiry Suschinsky', message: "#399 TX Courts - DOWNLOAD - DONE")
    rescue StandardError => e
      error_msg = e.backtrace.join("\n")
      Hamster.report(to: 'dmitiry.suschinsky', message: "#399 TX Courts DOWNLOAD - exception:\n #{error_msg}")
    end
  end

end
