# frozen_string_literal: true

require_relative 'transfer_cases/us_cases'
require_relative 'transfer_cases/transfer_run_id'

require_relative 'transfer_cases/transfer_saac_cases'


module UnexpectedTasks
  module UsCourts
    class TransferUsSaaCourts
      def self.run(**options)
        self.run_across_all_courts
        #TransferCasesSAAC.new(**options)
        limit = options[:limit] || 0
        days = options[:days] || 0
        #start_transfer(limit, days)
      end

      def self.run_across_all_courts
        UsCourtsSAAC.where(not_test:1).each do |court|
          p court.court_id
          begin
            TransferCasesSAAC.new({court_id:court.court_id })
          rescue =>e
            p e
            p '___________'
          end
          p '              '
        end
      end

    end

    class TransferCasesSAAC

      def initialize(**args)
        @court_id = args[:court_id] || 339
        @court_info = court_info(@court_id)
        @table_names = {
          :dev => make_table_names(@court_info.court_name_id),
          :root => make_table_names('us_saac'),
        }
        @run_id = 1
        if args[:table] && args[:table].to_sym.in?(tables_for_courts)
          transfer_data_to_root(args[:table].to_sym)
        else
          go_to_each_table
        end

      end

      def go_to_each_table
        tables_for_courts.each do |table|
          if table.in?(%i[info party activities additional_info pdfs_on_aws consolidations])
            transfer_data_to_root(table)
          else
            transfer_data_to_root_relations(table)
          end
        end
      end

      def transfer_data_to_root(table)
        limit = 100

        p table
        table_name_dev = @table_names[:dev][table]
        md5 = md5_class(table)
        #p table_name_dev
          if UsCourtsSAAC.connection.table_exists? table_name_dev
            db_model_dev = active_record_model(table_name_dev)
            db_model_root = active_record_model(@table_names[:root][table], 'us_courts')
            check_data = CheckData.new(table)
            page = 0
            loop do
              #p page
              offset = limit * page
              dev_rows = db_model_dev.where(deleted:0).limit(limit).offset(offset)
              new_md5_hashes = []
              rows_to_db = []

              ### Get data from dev table
              dev_rows.each do |row|
                new_row = check_data.check_row(row.serializable_hash.transform_keys(&:to_sym))
                new_row = adapt_rows(new_row)

                #md5_hash = md5.generate(new_row)
                #new_row[:md5_hash] = md5_hash
                new_md5_hashes.push(new_row[:md5_hash])

                new_row[:run_id] = @run_id
                new_row[:touched_run_id] = @run_id
                new_row = delete_unc_columns(new_row, table)
                rows_to_db.push(new_row)
              end

              existing_md5_hash = get_md5_hash(db_model_root, new_md5_hashes)

              ### Check data from dev table
              rows_to_db = rows_to_db.delete_if{|row| row[:md5_hash].in?(existing_md5_hash)}
              db_model_root.insert_all(rows_to_db) if !rows_to_db.empty?


              break if dev_rows.to_a.length<limit
              page+=1
            end

            page_deleted = 0
            loop do
              offset = limit * page_deleted
              dev_rows_deleted = db_model_dev.where(deleted:1).limit(limit).offset(offset)
              md5_hash_deleted = dev_rows_deleted.map { |row| row.md5_hash  }
              db_model_root.where(md5_hash:md5_hash_deleted).where(deleted:0).update(deleted:1)
              break if dev_rows_deleted.to_a.length<limit
              page_deleted+=1
            end

          else
            p table_name_dev
            p 'table is not exist'
            puts
          end
      end

      def transfer_data_to_root_relations(table)
        limit = 100
        page = 0

        table_name_dev = @table_names[:dev][table]

        if UsCourtsSAAC.connection.table_exists? table_name_dev
          p table
          db_model_dev = active_record_model(table_name_dev)
          db_model_root = active_record_model(@table_names[:root][table], 'us_courts')
          loop do
            offset = limit * page
            rows_to_db = []
            dev_rows = db_model_dev.limit(limit).offset(offset)

            dev_rows.each do |row|
              new_row = row.serializable_hash.transform_keys(&:to_sym)
              new_row[:court_id] = @court_id
              new_row = delete_unc_columns(new_row, table)
              rows_to_db.push(new_row)
            end

            db_model_root.insert_all(rows_to_db) if !rows_to_db.empty?

            break if dev_rows.to_a.length<limit
            page+=1
          end
        else
          p table_name_dev
          p 'table is not exist'
          puts
        end
      end

      def delete_unc_columns(old_row, table)
        new_row = {}
        columns[table].each do |row|
          new_row[row] = old_row[row]
        end
        new_row
      end

      private

      def get_md5_hash(db_model, md5_array)
        db_model.where(md5_hash:md5_array).update(touched_run_id:@run_id, deleted:0)
        db_model.where(md5_hash:md5_array).map { |row| row[:md5_hash]  }
      end

      def tables_for_courts
        %i[info party activities additional_info pdfs_on_aws
        relations_activity_pdf relations_info_pdf consolidations]
      end



      def md5_class(table_name)
        columns = columns_for_md5[table_name]
        MD5Hash.new(columns:columns)
      end

      def columns_for_md5
        {
          :info                     => %i[court_id case_id case_name case_filed_date case_type case_description disposition_or_status status_as_of_date judge_name],
          :party                    => %i[court_id case_id is_lawyer party_name party_type party_law_firm party_address party_city party_zip party_state party_description],
          :activities               => %i[court_id case_id activity_date activity_desc activity_type file],
          :additional_info          => %i[court_id case_id lower_court_name lower_case_id lower_judge_name lower_judgement_date lower_link disposition],
          :pdfs_on_aws              => %i[court_id case_id source_type aws_link source_link],
          :consolidations           => %i[court_id case_id consolidated_case_id consolidated_case_name consolidated_case_filled_date],
        }
      end

      def columns
        {
          :info                     => %i[court_id case_id case_name case_filed_date case_type case_description disposition_or_status status_as_of_date judge_name lower_court_id lower_case_id md5_hash created_by created_at updated_at data_source_url run_id touched_run_id deleted],
          :party                    => %i[court_id case_id is_lawyer party_name party_type party_law_firm party_address party_city party_zip party_state party_description md5_hash created_by created_at updated_at data_source_url run_id touched_run_id deleted],
          :activities               => %i[court_id case_id activity_date activity_desc activity_type file md5_hash created_by created_at updated_at data_source_url run_id touched_run_id deleted],
          :additional_info          => %i[court_id case_id lower_court_name lower_case_id lower_judge_name lower_judgement_date lower_link disposition md5_hash created_by created_at updated_at data_source_url run_id touched_run_id deleted],
          :pdfs_on_aws              => %i[court_id case_id source_type aws_link source_link md5_hash created_by created_at updated_at data_source_url run_id touched_run_id deleted],
          :consolidations           => %i[court_id case_id consolidated_case_id consolidated_case_name consolidated_case_filled_date md5_hash created_by created_at updated_at data_source_url run_id touched_run_id deleted],

          :relations_activity_pdf   => %i[court_id case_activities_md5 case_pdf_on_aws_md5 created_by created_at updated_at],
          :relations_info_pdf       => %i[court_id case_info_md5 case_pdf_on_aws_md5 created_by created_at updated_at],
        }
      end


      def make_table_names(court_name)
        {
          :info                     => "#{court_name}_case_info",
          :party                    => "#{court_name}_case_party",
          :activities               => "#{court_name}_case_activities",
          :additional_info          => "#{court_name}_case_additional_info",
          :pdfs_on_aws              => "#{court_name}_case_pdfs_on_aws",
          :relations_activity_pdf   => "#{court_name}_case_relations_activity_pdf",
          :relations_info_pdf       => "#{court_name}_case_relations_info_pdf",
          :consolidations           => "#{court_name}_case_consolidations",
        }
      end

      def active_record_model(table_name, database_name = 'us_court_cases')
        class_table = table_name.camelize

        assert "Bad table_name" if class_table.match(/\W/)
        eval("""
        class #{class_table} < ActiveRecord::Base
          self.inheritance_column = :_type_disabled
          self.table_name = '#{table_name}'
          establish_connection(Storage[host: :db01, db: :#{database_name}])
        end
      """)

        eval(class_table)
      end

      def court_info(court_id)
        UsCourtsSAAC.where(court_id:court_id).first
      end

      def adapt_rows(row)
        row.delete(:id)
        row
      end


    end

    class CheckData
      def initialize(table)
        @columns = columns_for_check[table]
      end

      def check_row(row)
        @columns.each do |column|
          row[column] = nil if !check_column_data(row[column])
        end
        row
      end

      def check_column_data(string) # replace emoji!
        return if string.nil?
        !string.downcase.in?(bad_rows)
      end

      private
      def bad_rows
        ['', '-', 'null', 'non', 'none', 'nil', '\n', 'unspecified', '^M']
      end

      def columns_for_check
        {
          :info                     => %i[case_name case_type case_description disposition_or_status status_as_of_date judge_name data_source_url],
          :party                    => %i[party_name party_type party_law_firm party_address party_city party_zip party_state party_description  data_source_url],
          :activities               => %i[data_source_url activity_desc activity_type file],
          :additional_info          => %i[lower_court_name lower_case_id lower_judge_name lower_link disposition data_source_url],
          :pdfs_on_aws              => %i[source_type aws_link source_link data_source_url],
          :relations_activity_pdf   => %i[],
          :relations_info_pdf       => %i[],
          :consolidations           => %i[consolidated_case_id consolidated_case_name data_source_url],
        }
      end

    end


  end
end





