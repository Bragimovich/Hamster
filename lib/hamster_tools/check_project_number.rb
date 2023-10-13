# frozen_string_literal: true

module Hamster
  module HamsterTools
    def check_project_number(command)
      raise "You have to put your task ID from #{SPREADSHEET}" unless @arguments[command].class == Integer
    end
  end
end
