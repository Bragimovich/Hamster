# frozen_string_literal: true

require_relative 'lib/limpar_test_parser'

module UnexpectedTasks
  module BoxScore
    class Games
      def self.run(**options)

        parser = LimparParser.new

        if options[:download]
          parser.start
        elsif options[:store]
          parser.start
        else
          parser.start
        end

      end
    end
  end
end