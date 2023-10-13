#require 'pg'


module UnexpectedTasks
  module UsCourts
    class CoordinatesToCounty
      def self.run(**options)
        self.start
        limit = options[:limit] || 0
        days = options[:days] || 0

      end

      def self.start
        con = PG.connect(host:'pl-gis.rds.locallabs.com', dbname:'pl_gis', user: 'app', password: 'VH3^@5mg%jz&B!6wMpj26CqP')

        CourtAddresses.all.each do |row|
          #p row[:latitude], row[:longitude]
          next if row[:longitude].nil?
          puts
          p row[:name]
          county_name = self.get_clean_county(con, row[:longitude], row[:latitude])
          row[:county] = county_name
          row.save
        end

      end

      def self.get_clean_county(host, lng, lat)
          query = <<~SQL
                SELECT s.name, c.name
                FROM counties c
                JOIN states s 
                  ON c.data->>'STATEFP' = s.data->>'STATEFP'
                WHERE ST_Within(ST_PointFromText('POINT(#{lng} #{lat})', 4326), c.the_geom);
          SQL
          data = host.query(query).to_a[0]
          p data
          data.nil? ? nil : data['name']
      end
    end


    class CourtAddresses < ActiveRecord::Base
      self.table_name = 'court_addresses'
      establish_connection(Storage[host: :db01, db: :us_courts_staging])
    end

  end
end