# frozen_string_literal: true

require 'logger'

# This class helps to create custom logs with ruby logger
class MainLogger
  def self.logger
    # Logger.new(File.open(log_path, 'a'), Logger::DEBUG)
    # Logger.new(File.open(@log_path, 'w'), Logger::DEBUG)
    Logger.new(STDOUT, Logger::DEBUG)
  end
end
