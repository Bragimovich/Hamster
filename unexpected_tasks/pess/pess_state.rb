# frozen_string_literal: true

require_relative 'pess_state/context'

module UnexpectedTasks
  module Pess
    module PessState
      def self.run(**options)
        Hamster.logger.info "Unexpected Task #{options[:do]} started!"
        Hamster.logger.info "Options: #{options}"

        begin
          Context.new(options).run
        rescue => e
          Hamster.logger.info e.full_message
          puts e.full_message
          raise e
        end
      end
    end
  end
end
