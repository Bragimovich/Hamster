# frozen_string_literal: true

# Main class. Needed to create base file structure, launch projects and other stuff.
# Contains module HamsterTools
require_relative 'hamster_tools'    # extends class Hamster with several methods
# and following methods:
require_relative 'hamster/do'       # launches side tasks
require_relative 'hamster/dig'      # creates base file structure
require_relative 'hamster/grab'     # launches projects
require_relative 'hamster/telegram' # launches hamster telegram listener
require_relative 'hamster/wakeup'   # gets command-line arguments and runs the method was called
require_relative 'hamster/version'  # the current project verstion
require_relative 'hamster/encrypt'  # encrypting a file using master.key or other secret key
require_relative 'hamster/decrypt'  # decrypting a file using master.key or other secret key
require_relative 'hamster/generate_key' # generate a secret key in /secrets
require_relative 'hamster/console'  # launch console for the given project number
require_relative 'hamster/logger'   # create a new logger
require_relative 'hamster/generate' # generate files for given resource(eg model)
require_relative 'hamster/loggable' # inject the logger object
require_relative 'hamster/table_receiver'   # get table columns as an array from a pdf

module Hamster
  PROJECT_DIR_NAME = 'project'

  extend HamsterTools
end
