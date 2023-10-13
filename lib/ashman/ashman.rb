
# The module Ashman contains all the code for the AWS S3.
# Written by Oleksii Kuts on Mar 02, 2023
require_relative 'lib/client'
require_relative 'lib/errors'

module Hamster
  module Ashman
    VERSION = '1.0.0'
    USER_AGENT = "Ashman/Ruby v#{VERSION}"
    def self.new(options = {:aws_opts => {}})
        Ashman::Client.new(options)
    end
  end
end
