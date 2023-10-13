# frozen_string_literal: true

module Hamster
  module Ashman

    # An error class for Ashman-related exceptions.
    class Error < StandardError
      # The additional information related to the error.
      attr_reader :info

      # Creates a new instance of Ashman::Error.
      #
      # @param msg [String] The error message.
      # @param info [Hash] Additional information related to the error.
      #
      # @return [Ashman::Error] The error message with additional information related to it
      #
      # @example Raise custom error if can't find file with the given key in bucket
      #   raise Ashman::Error.new("!!! Error: can't find the object", {bucket: bucket, key: key)
      # 
      def initialize(msg = "Ashman Exception", info = {})
        @info = info
        super(msg)
      end
    end

  end
end
