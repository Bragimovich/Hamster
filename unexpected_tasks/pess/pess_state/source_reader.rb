# frozen_string_literal: true

module UnexpectedTasks
  module Pess
    module PessState
      class SourceReader
        def initialize(context)
          @context = context
          @model   = @context.model.source_model
        end

        def read(offset, limit)
          dataset = filtered_collection.offset(offset).limit(limit)
          data = dataset.map do |rec|
            {

            }
          end
        end

        def total_count
          filtered_collection.count
        end

        private

        def filtered_collection
          if @filtered_collection.nil?
            @filtered_collection = @model
            where_clause = nil

            filters = @context.config.dig('source_main_table', 'filters')
            if filters.instance_of?(Array) && filters.present?
              where_clause = "(#{filters.join(' and ')})"
            end

            incls = @context.config.dig('source_main_table', 'includes')
            if incls.instance_of?(Array) && incls.present?
              where_clause = ([where_clause] + incls).compact.join(' or ')
            end

            @filtered_collection = @filtered_collection.where(where_clause) if where_clause.present?
          end

          @filtered_collection
        end
      end
    end
  end
end
