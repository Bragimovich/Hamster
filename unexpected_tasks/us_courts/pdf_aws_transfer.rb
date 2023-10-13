


module UnexpectedTasks
  module UsCourts
    class PdfAwsTransfer
      def self.run(**options)

        PdfTransfer.new(**options)
      end


    end

    class PdfTransfer
      def initialize(**options)
        @limit = options[:limit] || 0
        days = options[:days] || 0

        start
      end

      def delete
        aws_courts = AwsS3.new(bucket_key = :us_court, account=:us_court)
        aws_courts.find_files_in_s3('us_courts_old')
        #aws_courts.delete_files('us_courts_old_102')
      end


      def start

        aws_image = AwsS3.new(bucket_key = :image_processing, account=:us_court)
        aws_courts = AwsS3.new(bucket_key = :us_court, account=:us_court)

        [87, 97, 102,104].each do |court_id|
          p court_id
          column_name_link = column_with_pdf_link[court_id]
          column_name_activity = where_condition[court_id]
          @client = connect_to_db
          page = 0
          loop do
            pdf_links = get_link_pdfs(court_id, page, [column_name_link, column_name_activity[:orig]])
            pdf_links.each do |row|
              p row
              keyname = "hyperlocal/"+ row[:activity_pdf].split("hyperlocal/")[-1]
              filename =  "#{Time.now.to_i}_" + keyname.split('/')[-1].split('||')[0]
              path_to_file = '../pdf_files/image_processing/' + filename
              begin
                aws_image.download_file(keyname, path_to_file)
              rescue =>e
                p e
                next
              end
              new_keyname = "us_courts_old/#{court_id}/#{row[:case_id]}/#{filename}.pdf".gsub(' ', '')
              body = File.open(path_to_file, 'r')
              link_to_pdf = aws_courts.put_file(body, new_keyname)
              p link_to_pdf
              # activities = {
              #   column: column_name_activity[:new],
              #   value: row[column_name_activity[:orig].to_sym]
              # }
              #update_link_to_file(row[:case_number], link_to_pdf, activities)
              update_link_to_file_new(row[:case_id], link_to_pdf, row[:activity_id])
              File.delete(path_to_file)
            end
            break if pdf_links.to_a.length<@limit
            page = page+1
          end
        end
      end



      private

      def get_link_pdfs(court_id, page = 0, columns)
        table_name = database[court_id]
        #pdf_column_name = column_with_pdf_link[court_id]
        offset = page * @limit
        # query = "SELECT case_number, #{columns.join(',')} FROM #{table_name}
        #     WHERE #{columns[0]} is not null AND #{columns[0]}!=''
        #     AND case_number in (SELECT case_id FROM us_courts.us_case_activities WHERE court_id=#{court_id} and activity_pdf not like 'https://court-cases-activities.s3.amazonaws.com%')
        #     LIMIT #{@limit} OFFSET #{offset}"
        query = "SELECT id activity_id, case_id, activity_pdf FROM us_courts.us_case_activities
              WHERE court_id=#{court_id}
                AND activity_pdf not like 'https://court-cases-activities.s3.amazonaws.com%' AND activity_pdf is not null
              LIMIT #{@limit} OFFSET #{offset}"
        p query
        statement = @client.prepare(query)
        statement.execute
      end

      def update_link_to_file(case_id, link, activities)
        query = "UPDATE us_courts.us_case_activities SET activity_pdf = '#{link}' WHERE case_id = '#{case_id}' "
        query += "AND #{activities[:column]}='#{activities[:value]}' "
        p query
        @client.query(query)
      end


      def update_link_to_file_new(case_id, link, activity_id)
        query = "UPDATE us_courts.us_case_activities SET activity_pdf = '#{link}'
                WHERE case_id = '#{case_id}' AND id = #{activity_id}"
        @client.query(query)
      end

      def connect_to_db(database=:us_court_cases) #us_court_cases
        Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
      end


      def database
        {
          87 => 'usa_raw.delaware_county_court_case_activity_scrape',
          97 => 'usa_raw.san_francisco_court_case_activity_scrape', #?
          102 => 'usa_raw.bucks_county_court_case_activity_scrape',
          104 => 'usa_raw.fl_13th_case_activity_scrape'

        }
      end

      def column_with_pdf_link
        {
          87 => :pdf_path,
          #95 => :image_local,
          97 => :pdf_url,
          102 => :pdf_url,
          104 => :pdf_local
        }
      end

      def where_condition
        {
          87 => {orig: 'case_activity', new: 'activity_decs'},
          97 => {orig: 'pdf_url', new: 'activity_pdf'},
          102 => {orig: 'pdf_url', new: 'activity_pdf'},
          104 => {orig: 'pdf_local', new: 'activity_pdf'},
        }
      end

    end

  end
end