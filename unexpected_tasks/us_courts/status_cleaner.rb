# frozen_string_literal: true

module UnexpectedTasks
  module UsCourts
    class StatusCleaner
      def self.run(**options)
        db = Mysql2::Client.new(Storage[host: :db01, db: :us_courts].merge(symbolize_keys: true))

        db.query('USE us_courts')

        tables = {}
        %i[disposition_or_status status_as_of_date].each do |name|
          tables[name] = db.query("select id, #{name.to_s} from raw_uniq_#{name.to_s}").to_a
        end

        tables.each do |name, table|
          table.map! do |el|
            next if el[name].nil?

            clean =
              el[name].
              sub(/Disposition Date.*/i, '').
              sub(/^\d.*/, 'N/A').
              sub(/\(.*\d{4}.*\)/, '').
              sub(/( *[-–] *)?\d{1,2}[-\/]+\d{1,2}[-\/]+\d{2,4}/, '')
            db.query("UPDATE raw_uniq_#{name.to_s} set clean = \"#{clean}\" where id = #{el[:id]}")
          end
        end

      ensure
        db.close
      end
    end
  end
end

