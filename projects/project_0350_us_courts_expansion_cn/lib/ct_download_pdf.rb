
def connect_to_db(database = :us_court_cases)
  Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
end

class CTDownload < Hamster::Scraper
  def initialize(limit = 10, delete = 0)
    @limit = limit
    @client = connect_to_db
    @s3 = AwsS3.new(bucket_key = :us_court)
    @base_url = 'http://appellateinquiry.jud.ct.gov/'
    @semaphore = Mutex.new
    @run_id = CtSaacCaseRuns.last.id
  end

  #_______DATABASE_________
  def get_pdf_links(court_id, page: 0)
    offset = @limit * page
    query = "SELECT id, case_id, file, activity_desc, activity_date, md5_hash FROM us_court_cases.ct_saac_case_activities WHERE court_id = #{court_id}
              AND file is not null AND file != '' AND file NOT LIKE 'CaseDetail.aspx?CRN=%' AND activity_pdf = ''
              LIMIT #{@limit} OFFSET #{offset}"
    @client.query(query).to_a
  end

  def get_aws_links(page: 0)
    offset = @limit * page
    query = "SELECT aws_link FROM us_court_cases.ct_saac_case_pdfs_on_aws
             LIMIT #{@limit} OFFSET #{offset}"
    @client.query(query).to_a
  end

  def get_pdf_exist(client, case_id, source_link)
    query = "SELECT * FROM us_court_cases.ct_saac_case_pdfs_on_aws
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
    # ct_saac_case_pdfs_on_aws
    query = "INSERT INTO us_court_cases.ct_saac_case_pdfs_on_aws (court_id, case_id, source_type, aws_link, data_source_url, md5_hash, run_id)
             VALUES (#{court_id}, '#{case_data[:case_id]}', 'activity', '#{aws_lnk}', '#{@base_url + case_data[:file]}', '#{md5_hash}', #{@run_id})"
    client.query(query)

    # ct_saac_case_relations_activity_pdf
    query = "INSERT INTO us_court_cases.ct_saac_case_relations_activity_pdf (case_activities_md5, case_pdf_on_aws_md5)
             VALUES ('#{case_data[:md5_hash]}', '#{md5_hash}')"
    client.query(query)

    # ctsc_case_activities
    query = "UPDATE us_court_cases.ct_saac_case_activities SET activity_pdf = 'uploaded'
             WHERE id = #{case_data[:id]}"
    client.query(query)
  end

  #______DOWNLOAD______
  def download_files(type)
    begin
      cobble = Hamster::Scraper::Dasher.new(:using => :cobble)
      page = 0
      iter = 0

      if type == 'Supreme'
        court_id = 307
      elsif type == 'Appellate'
        court_id = 414
      else
        return nil
      end

      loop do
        result = get_pdf_links(court_id, page: page)
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

              next if row[:file].nil? or row[:file] == ' -'
              next if get_pdf_exist(client_1, row[:case_id], @base_url + row[:file])

              pdf_body = cobble.get(@base_url + row[:file])

              if row[:activity_desc].nil?
                activity_desc = '-'
              else
                activity_desc = row[:activity_desc]
              end
              metadata = {
                court_id: court_id.to_s,
                case_id: row[:case_id],
                activity_desc: activity_desc,
                activity_date: row[:activity_date].to_s
              }

              # us_courts_expansion_<court_id>_<case_id>_<file_name>              # key = "us_courts_expansion_#{metadata[:court_id]}_#{metadata[:case_id]}_#{row[:file].gsub('DocumentDisplayer.aspx?', '')}"
              key = "us_courts_expansion/#{metadata[:court_id]}/#{metadata[:case_id]}/#{row[:file].gsub('DocumentDisplayer.aspx?', '')}"

              url = aws_s3.put_file(pdf_body, key, metadata)

              md5_hash = {
                court_id: court_id.to_s,
                case_id: row[:case_id],
                aws_link: url,
                source_link: @base_url + row[:file]
              }

              cols = %i[court_id case_id aws_link source_link]
              md5 = MD5Hash.new(:columns => cols)
              md5.generate(md5_hash)

              put_filename_to_db(client_1, row, court_id, url, md5.hash)
            end
            client_1.close
          end
        end
        threads_links.each(&:join)

        break if result_size < @limit
        page += 1
      end

      Hamster.report(to: 'Dmitiry Suschinsky', message: "#350 Connecticut Courts - DOWNLOAD - DONE #{type}(#{iter})")
    rescue StandardError => e
      error_msg = e.backtrace.join("\n")
      Hamster.report(to: 'dmitiry.suschinsky', message: "#350 Connecticut Courts DOWNLOAD - exception #{type}(#{iter}):\n #{error_msg}")
    end
  end

  def down_from_url(url = '')
    res = connect_to(url)
    File.open("123.pdf", 'wb') { |fp| fp.write(res.body) }
  end

end
