module UnexpectedTasks
  module UsCourts
    class CleanColumns
      def self.run(**options)
        @db      = Mysql2::Client.new(Storage[host: options[:db], db: options[:dataset]].except(:adapter).merge(symbolize_keys: true))
        @table   = options[:table]
        @columns = options[:columns].split(',')
        clean_columns
      end

      private

      def self.clean_columns
        @columns.each do |column|
          query = <<~SQL
            UPDATE #{@table}
            SET #{column} = null
            WHERE
            #{column} IN ('', '-', 'null', 'non', 'none', 'nil', '\n', 'unspecified', '^M');
          SQL
          @db.query(query)
        end
        puts "Successfully cleaned #{@columns} in #{@table}"
      rescue StandardError => e
        puts "#{e} | #{e.full_message}"
      ensure
        @db&.close
      end
    end
  end
end
