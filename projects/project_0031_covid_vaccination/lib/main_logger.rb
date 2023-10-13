# frozen_string_literal: true

require 'logger'

# This class helps to create custom logs with ruby logger
class MainLogger
  def self.logger
    Logger.new(STDOUT, Logger::DEBUG)
  end
end
