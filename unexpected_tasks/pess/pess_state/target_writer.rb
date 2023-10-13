# frozen_string_literal: true

module UnexpectedTasks
  module Pess
    module PessState
      class TargetWriter
        def initialize(context)
          @context = context
        end

        def write_static_data
          # models
          dataset_model       = @context.model.dataset_model
          dataset_table_model = @context.model.dataset_table_model
          comp_types_model    = @context.model.compensation_type_model

          # write raw_datasets
          loc  = @context.config.dig('raw_datasets', 'raw_dataset_location')
          pref = @context.config.dig('raw_datasets', 'raw_dataset_prefix')
          name = @context.config.dig('raw_datasets', 'data_source_name')
          meth = @context.config.dig('raw_datasets', 'data_gather_method')
          src  = @context.config.dig('')
        end
      end
    end
  end
end
