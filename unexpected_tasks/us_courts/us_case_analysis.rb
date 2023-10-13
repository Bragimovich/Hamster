# frozen_string_literal: true

require_relative 'us_case_table_analysis/us_case_table_analysis_models'
require_relative 'case_types/us_case_types_IRL_model'

module UnexpectedTasks
  module UsCourts
    class UsCaseAnalysis
      def self.run(**options)
        limit = options[:limit] || 0
        days = options[:days] || 0
        UsCaseTableAnalysis.new() if options[:columns]
        UsCaseCourthouseAnalysis.new() if options[:courts]
        UsCaseCourthouseColumnAnalysis.new(update=1)  if options[:table]
        OverallDataAnalysis.new() if options[:overall]

        if options[:update]
          UsCaseTableAnalysis.new()
          UsCaseCourthouseAnalysis.new()
          UsCaseCourthouseColumnAnalysis.new(update=1)
        end

      end
    end

    class UsCaseTableAnalysis
      def initialize
        @table_name_to_table_id = table_name_to_table_id
        @table_id_to_table_name = table_id_to_table_name
        p 'START TABLE ANALYSIS....'
        start
        p 'END  TABLE ANALYSIS'
      end

      def start
        # UsCaseInfo.connection.tables.each do |table|
        #   p table
        # end
        data_points_in_table = get_existed_columns
        conn = connect_to_db
        query = "SHOW TABLES;"
        tables_in_db = conn.prepare(query).execute.map {|table| table.values[0]}

        tables_in_db.each do |table_name|
          #table_name = table
          data_for_message = {table: table_name}
          #new tables
          # end new tables
          if !table_name.in?(data_points_in_table)
            check_table_name(table_name)
            data_points_in_table[table_name] = {}
            courthouse_logs(:table, :append, data_for_message)
          end

          query = "Show columns from #{table_name};"
          column_info_in_db = conn.prepare(query).execute.map {|col| col}
          existed_columns_in_db = column_info_in_db.map {|col| col[:Field]}
          columns_in_db = []

          column_info_in_db.each do |column_info|
            column_name = column_info[:Field]
            column_type = column_info[:Type]
            data_for_message[:column] = column_name
            columns_in_db.push(column_name)
            if column_name.in? data_points_in_table[table_name]
              if column_type!=data_points_in_table[table_name][column_name]
                #ADD to table
                data_for_message[:type] = column_type
                data_for_message[:previous_type] = data_points_in_table[table_name][column_name]
                UsCaseDistinctDataPoints.where(deleted:0).where(table_id:@table_name_to_table_id[table_name])
                                        .where(data_point_name: column_name).update(data_point_type: column_type)
                courthouse_logs(:type, :change, data_for_message)
              end
            else
              courthouse_logs(:column, :append, data_for_message)
              new_column_data = {
                table_id: @table_name_to_table_id[table_name], data_point_name: column_name,
                data_point_type: column_type
              }
              UsCaseDistinctDataPoints.insert(new_column_data)
            end

            if 'court_id'.in?(existed_columns_in_db)
              query = "select count(*) cc from (select court_id, count(*) from #{table_name} where  #{column_name} is not null group by court_id) c"
              courts_rows = conn.prepare(query).execute.first
              counts_court_id_for_data_point = courts_rows[:cc]

              counted_row = UsCaseDistinctDataPoints.where(deleted:0).where(table_id:@table_name_to_table_id[table_name])
                                      .where(data_point_name: column_name)
              if counted_row.first[:total_courthouses_with_data]!=counts_court_id_for_data_point
                counted_row.update(total_courthouses_with_data: counts_court_id_for_data_point)
                data_for_message[:totals]=counted_row.first[:total_courthouses_with_data]
                courthouse_logs(:totals, :new, data_for_message)
              end

            end


          end

          #check_deleted_columns(columns_in_db)
          UsCaseDistinctDataPoints.where(deleted:0).where(table_id:@table_name_to_table_id[table_name]).each do |row|
            next if row.data_point_name.in?(columns_in_db)
            data_for_message[:column] = row.data_point_name
            courthouse_logs(:column, :delete, data_for_message)
            row.deleted=1
          end

        end

        UsCaseDistinctDataPoints.where(deleted:0).group(:table_id).each do |grouped_row|
          table_name = @table_id_to_table_name[grouped_row.table_id]
          next if table_name.in?(tables_in_db)
          p table_name
          data_for_message = {table: table_name}
          courthouse_logs(:table, :delete, data_for_message)
          UsCaseDistinctDataPoints.where(table_id:grouped_row.table_id).update(deleted:1)
          UsCaseLitigationDataSetTables.where(table_id:grouped_row.table_id).update(deleted_at:Date.today())
        end

      end

      def get_existed_columns
        db_data_points = {}

        table_id_to_table_name = {}
        UsCaseLitigationDataSetTables.all().map { |row| table_id_to_table_name[row.table_id] = row.table_name }

        UsCaseDistinctDataPoints.where(deleted:0).each do |data_point|
          table_name = table_id_to_table_name[data_point.table_id]
          db_data_points[table_name] = {} if !table_name.in?(db_data_points)
          db_data_points[table_name][data_point.data_point_name] = data_point.data_point_type
        end
        db_data_points
      end

      private

      def check_table_name(table_name)
        unless UsCaseLitigationDataSetTables.where(table_name:table_name).first
          UsCaseLitigationDataSetTables.insert({table_name:table_name})
          UsCaseLitigationDataSetTables.where(table_name:table_name).map{|table| @table_name_to_table_id[table.table_name] = table.table_id}
        end
      end

      def table_name_to_table_id
        table_name_to_table_id = {}
        UsCaseLitigationDataSetTables.all().map { |row| table_name_to_table_id[row.table_name] = row.table_id }
        table_name_to_table_id
      end

      def table_id_to_table_name
        table_name_to_table_id = {}
        UsCaseLitigationDataSetTables.all().map { |row| table_name_to_table_id[row.table_id] = row.table_name  }
        table_name_to_table_id
      end

      def courthouse_logs(type_message, action, data)
        data_to_db = {
          object_type: type_message.to_s, action: action.to_s,
          table_name: data[:table],
        }

        message =
          case type_message
          when :table
            if action == :append
              "New table: `#{data[:table]}`"
            elsif action == :delete
              "Delete table: `#{data[:table]}`"
            end
          when :column
            data_to_db[:column_name] = data[:column]
            if action == :append
              "In table `#{data[:table]}` column `#{data[:column]}` was append "
            elsif action == :delete
              "In table `#{data[:table]}` column `#{data[:column]}` was deleted "
            end
          when :type
            data_to_db[:column_name] = data[:column]
            "In table `#{data[:table]}` column `#{data[:column]}` changed type from #{data[:previous_type]} on #{data[:type]} "
          when :totals
            "Totals courthouse with data was increased from #{data[:totals]} in table `#{data[:table]}` column `#{data[:column]}` "
          end
        data_to_db[:message] = message

        UsCaseCourthouseLogs.insert(data_to_db)
      end

      def connect_to_db(database=:us_courts) #us_court_cases
        Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
      end

    end


    class UsCaseCourthouseAnalysis
      def initialize
        p 'START courthouse analysis ...'
        p 'General courts'
        start
        p 'Supreme and Appelate courts'
        start_saac
        p 'END courthouse analysis ...'
      end

      def start
        cases = UsCaseInfo.group(:court_id).maximum(:created_at)

        cases_last_update = {}
        UsCaseInfo.group(:court_id).maximum(:updated_at).map {|row| cases_last_update[row[0]]=row[1]}

        cases.each do |court_id, last_date|
          courthouses = {
            court_id: court_id, last_scrape_date: last_date
          }
          courthouses[:total_cases] = UsCaseInfo.where(court_id:court_id).count
          courthouses[:total_new_cases_from_last_scrape] = UsCaseInfo.where(court_id:court_id).where("created_at > ?", last_date.next_day(-1)).count
          courthouses[:scheduled_next_scrape_date] = last_date.next_day(1)
          courthouses[:last_updated] = cases_last_update[court_id]

          courthouses[:total_judges] = UsCaseInfo.where(court_id:court_id).select(:judge_name).distinct.count
          criminal_where = "case_type in ('CRIMINAL Miscellaneous','Petition on Criminal Case','Appeals - Criminal Other - Other Criminal','Appeals - Criminal Misdemeanor - Assault Related''Appeals - Criminal Misdemeanor - Domestic Violence','CRIMINAL, EXPEDITED','Appeals - Criminal Felony - Weapons Related','MUNI CRIMINAL TRAFFIC','CRIMINAL','Criminal-Clerk')"
          courthouses[:total_criminal] = UsCaseInfo.where(court_id:court_id).where("case_type LIKE ? or #{criminal_where}", "%criminal%").count
          family_where = "case_type in ('Domestic Family', 'Matrimonial - Contested', 'CHILD SUPPORT', 'Paternity', 'FAMILY', 'FAMILY, EXPEDITED', 'Other Matters - Application to Docket ', 'Family Court Judgment','Child Support - Agency','UIFSA - Uniform Interstate Family Support Act','Appeals - Family - Domestic Relations','Appeals - Family - Domestic Violence','Paternity / Parentage - Agency')"
          courthouses[:total_family] = UsCaseInfo.where(court_id:court_id).where("case_type LIKE ? or #{family_where}", "%family%").count
          courthouses[:total_criminal_family] = UsCaseInfo.where(court_id:court_id).where("case_type LIKE (?) or case_type LIKE (?) or #{criminal_where} or #{family_where}", "%family%", "%criminal%").count

          courthouses[:total_civil] = courthouses[:total_cases] - courthouses[:total_criminal_family]
          courthouses[:total_3tier_category] = UsCaseTypesIRLCategorized.where(court_id:court_id).where(priority:'Tier 3').map { |row| row.count }.sum
          where_tier_3 = "case_type not in ('Domestic Family', 'Matrimonial - Contested', 'CHILD SUPPORT', 'Paternity', 'FAMILY', 'FAMILY, EXPEDITED', 'Other Matters - Application to Docket ', 'Family Court Judgment','Child Support - Agency','UIFSA - Uniform Interstate Family Support Act','Appeals - Family - Domestic Relations','Appeals - Family - Domestic Violence','Paternity / Parentage - Agency', 'CRIMINAL Miscellaneous','Petition on Criminal Case','Appeals - Criminal Other - Other Criminal','Appeals - Criminal Misdemeanor - Assault Related''Appeals - Criminal Misdemeanor - Domestic Violence','CRIMINAL, EXPEDITED','Appeals - Criminal Felony - Weapons Related','MUNI CRIMINAL TRAFFIC','CRIMINAL','Criminal-Clerk')"
          courthouses[:total_3tier_category_civil_cases] = UsCaseTypesIRLCategorized.where(court_id:court_id).where(priority:'Tier 3').where(where_tier_3).map { |row| row.count }.sum
          p courthouses
          courthouse_row_in_table = UsCaseCourthouseCounts.where(court_id:court_id)

          if courthouse_row_in_table[0].nil?
            UsCaseCourthouseCounts.insert(courthouses)
          else
            courthouse_row_in_table.update(courthouses)
          end

        end

      end

      def tier3_category(court_id)
        UsCaseInfo
      end

      def start_saac
        cases = UsSAACCaseInfo.group(:court_id).maximum(:created_at)

        cases_last_update = {}
        UsSAACCaseInfo.group(:court_id).maximum(:updated_at).map {|row| cases_last_update[row[0]]=row[1]}

        cases.each do |court_id, last_date|
          courthouses = {
            court_id: court_id, last_scrape_date: last_date
          }
          courthouses[:total_cases] = UsSAACCaseInfo.where(court_id:court_id).count
          courthouses[:total_new_cases_from_last_scrape] = UsSAACCaseInfo.where(court_id:court_id).where("created_at > ?", last_date.next_day(-1)).count
          courthouses[:scheduled_next_scrape_date] = last_date.next_day(1)
          courthouses[:last_updated] = cases_last_update[court_id]


          courthouses[:total_judges] = UsSAACCaseInfo.where(court_id:court_id).select(:judge_name).distinct.count
          criminal_where = "case_type in ('CRIMINAL Miscellaneous','Petition on Criminal Case','Appeals - Criminal Other - Other Criminal','Appeals - Criminal Misdemeanor - Assault Related''Appeals - Criminal Misdemeanor - Domestic Violence','CRIMINAL, EXPEDITED','Appeals - Criminal Felony - Weapons Related','MUNI CRIMINAL TRAFFIC','CRIMINAL','Criminal-Clerk')"
          courthouses[:total_criminal] = UsSAACCaseInfo.where(court_id:court_id).where(criminal_where).count
          family_where = "case_type in ('Domestic Family', 'Matrimonial - Contested', 'CHILD SUPPORT', 'Paternity', 'FAMILY', 'FAMILY, EXPEDITED', 'Other Matters - Application to Docket ', 'Family Court Judgment','Child Support - Agency','UIFSA - Uniform Interstate Family Support Act','Appeals - Family - Domestic Relations','Appeals - Family - Domestic Violence','Paternity / Parentage - Agency')"
          courthouses[:total_family] = UsSAACCaseInfo.where(court_id:court_id).where(family_where).count #.where("case_type LIKE ? or #{family_where}", "%family%")
          courthouses[:total_criminal_family] = UsCaseInfo.where(court_id:court_id).where("case_type LIKE (?) or case_type LIKE (?) or #{criminal_where} or #{family_where}", "%family%", "%criminal%").count

          courthouses[:total_civil] = courthouses[:total_cases] - courthouses[:total_criminal_family]
          courthouses[:total_3tier_category] = UsCaseTypesIRLCategorized.where(court_id:court_id).where(priority:'Tier 3').map { |row| row.count }.sum
          where_tier_3 = "case_type not in ('Domestic Family', 'Matrimonial - Contested', 'CHILD SUPPORT', 'Paternity', 'FAMILY', 'FAMILY, EXPEDITED', 'Other Matters - Application to Docket ', 'Family Court Judgment','Child Support - Agency','UIFSA - Uniform Interstate Family Support Act','Appeals - Family - Domestic Relations','Appeals - Family - Domestic Violence','Paternity / Parentage - Agency', 'CRIMINAL Miscellaneous','Petition on Criminal Case','Appeals - Criminal Other - Other Criminal','Appeals - Criminal Misdemeanor - Assault Related''Appeals - Criminal Misdemeanor - Domestic Violence','CRIMINAL, EXPEDITED','Appeals - Criminal Felony - Weapons Related','MUNI CRIMINAL TRAFFIC','CRIMINAL','Criminal-Clerk')"
          courthouses[:total_3tier_category_civil_cases] = UsCaseTypesIRLCategorized.where(court_id:court_id).where(priority:'Tier 3').where(where_tier_3).map { |row| row.count }.sum

          courthouse_row_in_table = UsCaseCourthouseCounts.where(court_id:court_id)

          if courthouse_row_in_table[0].nil?
            UsCaseCourthouseCounts.insert(courthouses)
          else
            courthouse_row_in_table.update(courthouses)
          end
        end
      end
    end

    class UsCaseCourthouseColumnAnalysis
      def initialize(update=0)
        p 'START tables of courthouses analysis ...'
        #@list_court_id = courts
        #p @list_court_id
        @tables = table_id_to_table_name
        start
        p 'END tables of courthouses analysis ...'
      end

      def start
        client = connect_to_db

        existed_data_points = existed_data_points_in_table
        court_id_to_name = courts
        UsCaseDistinctDataPoints.where(deleted:0).each do |data_point|
          next if data_point.id.in?(existed_data_points)
          table_name = @tables[data_point.table_id]

          query = "Show columns from #{table_name}"
          next unless 'court_id'.in? client.prepare(query).execute.map {|col| col[:Field]}

          column_name = data_point.data_point_name
          p "#{table_name}: #{column_name}"
          data_to_db = []

          query = "SELECT court_id, count(DISTINCT #{column_name}) as total_distinct_values, count(*)-count(#{column_name}) as total_null_records, count(*) as total_cases FROM #{table_name} GROUP BY court_id"
          courts_rows = client.prepare(query).execute
          courts_rows.each do |row|
            row[:data_point_id] = data_point.id
            row[:data_point_name] = column_name
            row[:court_name] = court_id_to_name[row[:court_id]]
            row[:percent_null] = row[:total_null_records].to_f/row[:total_cases].to_f * 100
            data_to_db.push(row)

            # if update==1
            #   old_row = UsCaseCourthouseDataPointAnalysis.where(data_point_id:data_point.id).where(court_id:row[:court_id])
            #   if !old_row[0].nil?
            #     old_row.update(row)
            #   else
            #
            #   end
            # end
          end


          #UsCaseCourthouseDataPointAnalysis.where(data_point_id:data_point.id).delete
          UsCaseCourthouseDataPointAnalysis.insert_all(data_to_db) if !data_to_db.empty?
        end
      end

      def existed_data_points_in_table
        UsCaseCourthouseDataPointAnalysis.group(:data_point_id).map {|row| row.data_point_id}
      end

      private

      def connect_to_db(database=:us_courts) #us_court_cases
        Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
      end

      def table_id_to_table_name
        table_name_to_table_id = {}
        UsCaseLitigationDataSetTables.all().map { |row| table_name_to_table_id[row.table_id] = row.table_name  }
        table_name_to_table_id
      end

      def courts
        court_id_to_name = {}
        UsCaseCourthouseCounts.all().map{ |row| court_id_to_name[row.court_id] = row.court_name}
        court_id_to_name
      end

    end


    class OverallDataAnalysis
      def initialize
        start
      end

      def start
        client = connect_to_db
        court_id_to_name = courts

        judges_in_mbo_query = "SELECT court_id, count(*) as judges from us_case_info where judge_name in (
              SELECT uj.judge_name
              from us_judges_clean ujc
                       join us_judges uj on uj.id=ujc.judge_id
                       join us_courts_table courts on courts.court_id = ujc.court_id
              where ujc.judge_id_mbo is not null)
          group by court_id"

        judges_courts = {}
        courts_rows = client.prepare(judges_in_mbo_query).execute#.map{|row| judges_courts[row[:court_id]]=row[:judges]}

        courts_rows.each do |row|
          p row[:court_id]
          court_id = row[:court_id]
          next if row[:court_id].nil? or court_id.in?([1,2,3,4])
          court_info = {
            court_id: court_id,
            court_name: court_id_to_name[court_id],
            total_cases: UsCaseInfo.where(court_id:court_id).count,
            total_cases_with_judge_bio: row[:judges]
          }

          lawyers_in_mbo_query = "SELECT * from us_case_party ucp
            join us_case_laywers_mbo uclm on ucp.party_name = uclm.lawyer_name
            where uclm.deleted=0 and court_id=#{court_id}
                group by ucp.case_id"
          court_info[:total_cases_with_lawyer_bio] = client.prepare(lawyers_in_mbo_query).execute.to_a.length


          lawyers_and_judges_in_mbo_query = "SELECT count(*) as c from us_case_info where judge_name in (
                SELECT uj.judge_name
                from us_judges_clean ujc
                         join us_judges uj on uj.id=ujc.judge_id
                         join us_courts_table courts on courts.court_id = ujc.court_id
                where ujc.judge_id_mbo is not null)
                and court_id=#{court_id}
                and case_id in (SELECT case_id from us_case_party ucp
                                                  join us_case_laywers_mbo uclm on ucp.party_name = uclm.lawyer_name
                                where uclm.deleted=0 and court_id=#{court_id});"

          court_info[:total_cases_with_lawyer_and_judge] = client.prepare(lawyers_and_judges_in_mbo_query).execute.first[:c]

          p court_info
          row_for_court_id = UsCaseOverallDataAnalysis.where(court_id:court_id)
          if row_for_court_id[0].nil?
            UsCaseOverallDataAnalysis.insert(court_info)
          else
            row_for_court_id.update(court_info)
          end

        end

        judges_lawyers_in_mbo = "SELECT court_id, count(*) from us_case_info where judge_name in (
            SELECT uj.judge_name
            from us_judges_clean ujc
                     join us_judges uj on uj.id=ujc.judge_id
                     join us_courts_table courts on courts.court_id = ujc.court_id
            where ujc.judge_id_mbo is not null)
        group by court_id"

      end


      private

      def connect_to_db(database=:us_courts) #us_court_cases
        Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
      end

      def courts
        court_id_to_name = {}
        UsCaseCourthouseCounts.all().map{ |row| court_id_to_name[row.court_id] = row.court_name}
        court_id_to_name
      end

    end

  end
end
