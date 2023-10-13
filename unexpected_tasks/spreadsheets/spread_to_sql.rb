# Example run command
#bundle exec ruby hamster.rb --do=spreadsheets/spread_to_sql --host=db02
# --schema=hle_resources --sheet=Sheet1 --table_name=test_g_sheets_1 --id_doc=4Ddfi5enJSDF
# --created_by='Eldar Eminov' --types=int,,DATE,100

#write id_doc or name_doc
#types   - write type data with a comma. int - integer, date - DATE
#default type -- Varchar(255) for change size write only number
#columns - write columns names with a comma.
#sheet   - write tab name from google spreadsheet file
#link    - write link from google spreadsheet file

require 'google_drive'

module UnexpectedTasks
  module Spreadsheets
    class SpreadToSql
      DEFAULT_TYPE = 'VARCHAR(255)'
      def self.run(**options)
        initialize_options(options)
        if @sheet
          worksheet = @spreadsheet.worksheets.find { |i| i.title == @sheet }
          raise Google::Apis::ClientError.new "Incorrect worksheet name #{@sheet}" unless worksheet

          save_data(worksheet)
        else
          @spreadsheet.worksheets.each { |worksheet| save_data(worksheet) }
        end
        message = "Success converted Google spreadsheet #{@name_doc || @id_doc} to sql in db: #{@host}.#{@schema}"
        notify message
        Hamster.report(to: @created_by, message: "##{Hamster.project_number} | #{message}", use: :both) if @created_by
      rescue => e
        notify(e.message, :red)
        notify(e.full_message, nil)
        notify("#{'#'*100}", :red)
        Hamster.report(to: @created_by, message: "##{Hamster.project_number} | #{e.message}", use: :both) if @created_by
      end

      private

      def self.notify(message, color=:green)
        method_ = @debug ? :debug : :info
        message = color.nil? ? message : message.send(color)
        Hamster.logger.send(method_, message)
      end

      def self.initialize_options(options)
        @debug      = ARGV.include?('--debug')
        @host       = options[:host]
        @sheet      = options[:sheet]
        @name_doc   = options[:name_doc]
        @id_doc     = options[:id_doc] || options[:link]&.split('/')&.at(5)
        @created_by = options[:created_by]
        @columns    = options[:columns]&.split(',')
        @types      = options[:types] ? options[:types].split(',') : []
        @table_name = options[:table_name] || @sheet.underscore.gsub(/\s/, '_')
        @schema     = options[:schema] #|| @spreadsheet.name.parameterize.underscore
        check_options
        @spreadsheet = connect_spreadsheet
        @db = Mysql2::Client.new(Storage[host: @host, db: @schema].except(:adapter).merge(symbolize_keys: true))
      end

      def self.check_options
        if @host.nil? || @schema.nil? || (@id_doc.nil? && @name_doc.nil?)
          notify('Оne or more required arguments are missing!', :red)
          notify('Specify all arguments: [host, schema], specify one of the arguments: [id_doc, link, name_doc]', :red)
          exit
        end
        notify('created_by column not specified! [created_by]', :red) if @created_by.nil?
      end

      def self.connect_spreadsheet
        credentials = Google::Auth::UserRefreshCredentials.new(Storage.new.auth_hamster)
        session     = GoogleDrive::Session.from_credentials(credentials)
        arg         = @id_doc || @name_doc
        method_doc  = @id_doc ? :file_by_id : :spreadsheet_by_title
        spreadsheet = session.send(method_doc, arg)
        message     = "Make sure you enter the correct Google spreadsheet name."
        spreadsheet ? spreadsheet : (raise Google::Apis::ClientError.new message)
      end

      def self.save_data(worksheet)
        rows = worksheet.rows
        return check_worksheet(worksheet) if rows.empty?

        @columns ||= rows[0].dup
        @table_name = worksheet.title.parameterize.underscore if @sheet.nil? || @table_name.nil?
        @columns.each_with_index { |val, idx| @columns[idx] = 'id_1' if val == 'id' }
        for_skip  = @columns == rows[0] ? rows[0] : nil
        @data     = ''
        line_size = rows[0].size
        correct_types(line_size)
        rows.each do |row|
          next if row == for_skip

          new_row = prepare_line(row)
          @data += "(#{new_row})".sub(/, \)$/, '), ')
        end
        @data.sub!(/, $/, '')
        prepare_columns_names(line_size)
        query = prepare_query
        begin
          create_table(query)
          notify "Table '#{@table_name}' created"
        rescue Mysql2::Error => mysql_error
          notify(mysql_error.message, :red)
        end
        populate_table
        notify "Success add lines in table #{@table_name}"
      end

      def self.check_worksheet(worksheet)
        if @sheet || @spreadsheet.worksheets.size == 1
          raise Google::Apis::ClientError.new message
        else
          notify("Google table #{worksheet.title} is empty", :red)
        end
      end

      def self.prepare_query
        table = ''
        @columns.each_with_index { |name, idx| table += "`#{name}` #{@types[idx]} DEFAULT NULL, " }
        table
      end

      def self.prepare_columns_names(num)
        count = 0
        num.times { |i| @columns[i] = "unknown_#{count += 1}" if @columns[i].blank? }
      end

      def self.correct_types(num)
        num.times do |idx|
          if @types[idx].nil? || @types[idx].empty? || @types[idx] == '0'
            @types[idx] = DEFAULT_TYPE
          elsif !@types[idx].strip.to_i.zero?
            @types[idx] = DEFAULT_TYPE.sub('255', @types[idx].strip)
          end
        end
      end

      def self.prepare_line(line)
        new_line = ''
        line.each_with_index do |val, idx|
          if @types[idx].downcase.match?(/var/)
            new_line << (val.strip.empty? ? 'null, ' : "'#{val.gsub("'", '’')}', ")
          elsif @types[idx].downcase.match?(/date/)
            begin
              new_line << "'#{Date.parse(val).to_s}', "
            rescue Date::Error => date_error
              notify(date_error.message, :red)
              new_line << "null, "
            end
          elsif @types[idx].downcase.match?(/int/)
            new_line << "#{val}, "
          end
        end
        new_line
      end

      def self.create_table(table)
        query = <<~SQL
          CREATE TABLE `#{@table_name}`
          (
          `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
          #{table}
          `md5_hash`              VARCHAR(32)        DEFAULT NULL,
          `created_by`            VARCHAR(20)        DEFAULT '#{@created_by}',
          `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
          `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
          UNIQUE KEY `md5_hash` (`md5_hash`)
          ) DEFAULT CHARSET = `utf8mb4`
            COLLATE = utf8mb4_unicode_520_ci;
        SQL
        @db.query(query)
      end

      def self.populate_table
        str = ''
        @columns.each { |i| str << "`#{i}`, " }
        str.sub!(/, $/, '')
        query = <<~SQL
          INSERT INTO `#{@table_name}` (#{str})
          VALUE #{@data};
        SQL
        @db.query(query)
      end
    end
  end
end
