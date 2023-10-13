# frozen_string_literal: true

module UnexpectedTasks
  module Pess
    module PessState
      class Model
        def initialize(context)
          @context = context
        end

        def compensation_type_model
          @compensation_type_model ||=
            build_model(
              'TargetCompensationType',
              @context.config['db_host'],
              @context.config['target_db'],
              target_table_name('compensation_types')
            )
        end

        def dataset_model
          @dataset_model ||=
            build_model(
              'TargetRawDataset',
              @context.config['db_host'],
              @context.config['target_db'],
              target_table_name('raw_datasets')
            )
        end

        def dataset_table_model
          @dataset_table_model ||=
            build_model(
              'TargetRawDatasetTable',
              @context.config['db_host'],
              @context.config['target_db'],
              target_table_name('raw_dataset_tables')
            )
        end

        def source_model
          @source_mode ||=
            build_model(
              'PessSource',
              @context.config['db_host'],
              @context.config['source_db'],
              @context.config.dig('source_main_table', 'name')
            )
        end

        private

        def build_model(name, host, db, table)
          model = Object.const_get(name) rescue nil
          if model.nil?
            model = Class.new(ActiveRecord::Base)
            Object.const_set(name, model)
            name.constantize.establish_connection(Storage[host: host, db: db])
            name.constantize.table_name = table
          end

          name.constantize
        end

        def target_table_name(table)
          return table if @context.prefix.blank?

          "#{@context.prefix}_#{table}"
        end
      end
    end
  end
end
