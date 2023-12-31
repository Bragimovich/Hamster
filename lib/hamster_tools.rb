# frozen_string_literal: true

require_relative 'hamster_tools/assemble_uri'
require_relative 'hamster_tools/check_project_number'
require_relative 'hamster_tools/connect_to'
require_relative 'hamster_tools/commands'
require_relative 'hamster_tools/countdown'
require_relative 'hamster_tools/file'
require_relative 'hamster_tools/log'
require_relative 'hamster_tools/parse_arguments'
require_relative 'hamster_tools/peon'
require_relative 'hamster_tools/project_number'
require_relative 'hamster_tools/report'
require_relative 'hamster_tools/response_cookies'
require_relative 'hamster_tools/unexpected_task'
require_relative 'hamster_tools/check_options'
require_relative 'hamster_tools/close_connection'
# require_relative 'hamster_tools/captcha_adapter'

module Hamster
  module HamsterTools
    SPREADSHEET = 'https://lokic.locallabs.com/scrape_tasks'
  end
end
