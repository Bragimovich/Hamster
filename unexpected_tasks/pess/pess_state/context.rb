# frozen_string_literal: true

require_relative 'config'
require_relative 'model'
require_relative 'source_reader'
require_relative 'target_writer'

module UnexpectedTasks
  module Pess
    module PessState
      class Context
        DATA_PROCESS_COUNT = 500

        attr_reader :compensation_types
        attr_reader :config
        attr_reader :datamap
        attr_reader :dataset_table_id
        attr_reader :model
        attr_reader :prefix
        attr_reader :work_state

        def initialize(options)
          @options = options
          @prefix  = @options[:prefix].presence || ''
          @config  = Config.new(@options[:state])
          @model   = Model.new(self)
          @reader  = SourceReader.new(self)
          @writer  = TargetWriter.new(self)
        end

        def run
          @dataset_table_id, @compensation_types = @writer.write_static_data
          total_src_count = @reader.total_count

        end
      end
    end
  end
end
