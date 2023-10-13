# frozen_string_literal: true

require 'forwardable'
require 'yaml'

module UnexpectedTasks
  module Pess
    module PessState
      class Config
        extend Forwardable

        def_delegators :@config, :[], :dig

        def initialize(state)
          raise 'No state provided' if state.blank?

          cfg_file = "#{__dir__}/../state_config/#{state}.yml"
          @config  = YAML.load_file(cfg_file)
        end
      end
    end
  end
end
